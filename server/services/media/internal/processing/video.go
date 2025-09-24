package processing

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/h2non/filetype"
	"github.com/sirupsen/logrus"
)

// VideoProcessor handles video processing operations
type VideoProcessor struct {
	thumbnailSize int
	thumbnailTime int // seconds into video
}

// NewVideoProcessor creates a new video processor
func NewVideoProcessor(thumbnailSize, thumbnailTime int) *VideoProcessor {
	return &VideoProcessor{
		thumbnailSize: thumbnailSize,
		thumbnailTime: thumbnailTime,
	}
}

// ProcessVideo processes an uploaded video file
func (vp *VideoProcessor) ProcessVideo(reader io.Reader, filename string) (*VideoProcessingResult, error) {
	// Read the video data
	videoData, err := io.ReadAll(reader)
	if err != nil {
		return nil, fmt.Errorf("failed to read video data: %w", err)
	}

	// Validate file type
	fileType, err := filetype.Match(videoData)
	if err != nil {
		return nil, fmt.Errorf("failed to detect file type: %w", err)
	}

	if !filetype.IsVideo(videoData) {
		return nil, fmt.Errorf("file is not a valid video")
	}

	// Extract metadata using FFmpeg
	metadata, err := vp.extractVideoMetadata(videoData)
	if err != nil {
		logrus.Warnf("Failed to extract video metadata: %v", err)
		metadata = make(map[string]interface{})
	}

	// Generate thumbnail
	thumbnailData, err := vp.generateThumbnail(videoData)
	if err != nil {
		logrus.Warnf("Failed to generate thumbnail: %v", err)
	}

	// Optimize video for web delivery
	optimizedData, err := vp.optimizeVideo(videoData)
	if err != nil {
		logrus.Warnf("Failed to optimize video: %v", err)
		optimizedData = videoData // Use original if optimization fails
	}

	return &VideoProcessingResult{
		OriginalData:  videoData,
		OptimizedData: optimizedData,
		ThumbnailData: thumbnailData,
		Metadata:      metadata,
		Format:        vp.getVideoFormat(filename),
		MimeType:      fileType.MIME.Value,
	}, nil
}

// extractVideoMetadata extracts metadata from the video using FFmpeg
func (vp *VideoProcessor) extractVideoMetadata(videoData []byte) (map[string]interface{}, error) {
	// Check if FFmpeg is available
	if !vp.isFFmpegAvailable() {
		logrus.Warn("FFmpeg not available, skipping video metadata extraction")
		return map[string]interface{}{
			"width":    0,
			"height":   0,
			"duration": 0,
			"codec":    "unknown",
		}, nil
	}

	// Create a temporary file for FFmpeg
	tempFile, err := os.CreateTemp("", "video_*.mp4")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())
	defer tempFile.Close()

	// Write video data to temp file
	if _, err := tempFile.Write(videoData); err != nil {
		return nil, fmt.Errorf("failed to write video data: %w", err)
	}
	tempFile.Close()

	// Run FFmpeg to extract metadata
	cmd := exec.Command("ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", tempFile.Name())
	output, err := cmd.Output()
	if err != nil {
		logrus.Warnf("FFmpeg metadata extraction failed: %v", err)
		// Return default metadata instead of failing
		return map[string]interface{}{
			"width":    0,
			"height":   0,
			"duration": 0,
			"codec":    "unknown",
		}, nil
	}

	// Parse FFmpeg output (simplified - in production, use proper JSON parsing)
	metadata := make(map[string]interface{})

	// Extract basic info from FFmpeg output
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "\"width\"") {
			// Extract width
			if width := vp.extractJSONValue(line, "width"); width != "" {
				if w, err := strconv.Atoi(width); err == nil {
					metadata["width"] = w
				}
			}
		}
		if strings.Contains(line, "\"height\"") {
			// Extract height
			if height := vp.extractJSONValue(line, "height"); height != "" {
				if h, err := strconv.Atoi(height); err == nil {
					metadata["height"] = h
				}
			}
		}
		if strings.Contains(line, "\"duration\"") {
			// Extract duration
			if duration := vp.extractJSONValue(line, "duration"); duration != "" {
				if d, err := strconv.ParseFloat(duration, 64); err == nil {
					metadata["duration"] = int(d)
				}
			}
		}
		if strings.Contains(line, "\"codec_name\"") {
			// Extract codec
			if codec := vp.extractJSONValue(line, "codec_name"); codec != "" {
				metadata["codec"] = codec
			}
		}
		if strings.Contains(line, "\"bit_rate\"") {
			// Extract bitrate
			if bitrate := vp.extractJSONValue(line, "bit_rate"); bitrate != "" {
				if b, err := strconv.Atoi(bitrate); err == nil {
					metadata["bitrate"] = b
				}
			}
		}
		if strings.Contains(line, "\"r_frame_rate\"") {
			// Extract framerate
			if framerate := vp.extractJSONValue(line, "r_frame_rate"); framerate != "" {
				// Parse framerate (e.g., "30/1")
				parts := strings.Split(framerate, "/")
				if len(parts) == 2 {
					if num, err := strconv.Atoi(parts[0]); err == nil {
						if den, err := strconv.Atoi(parts[1]); err == nil && den > 0 {
							metadata["framerate"] = num / den
						}
					}
				}
			}
		}
	}

	// Set default values if not found
	if metadata["width"] == nil {
		metadata["width"] = 0
	}
	if metadata["height"] == nil {
		metadata["height"] = 0
	}
	if metadata["duration"] == nil {
		metadata["duration"] = 0
	}
	if metadata["codec"] == nil {
		metadata["codec"] = "unknown"
	}

	return metadata, nil
}

// extractJSONValue extracts a value from a JSON line
func (vp *VideoProcessor) extractJSONValue(line, key string) string {
	// Simple JSON value extraction (in production, use proper JSON parsing)
	keyPattern := "\"" + key + "\""
	start := strings.Index(line, keyPattern)
	if start == -1 {
		return ""
	}

	start += len(keyPattern)
	start = strings.Index(line[start:], ":")
	if start == -1 {
		return ""
	}
	start += len(":")

	// Find the value
	valueStart := start
	for valueStart < len(line) && (line[valueStart] == ' ' || line[valueStart] == '\t') {
		valueStart++
	}

	valueEnd := valueStart
	for valueEnd < len(line) && line[valueEnd] != ',' && line[valueEnd] != '}' {
		valueEnd++
	}

	value := line[valueStart:valueEnd]
	value = strings.Trim(value, "\"")

	return value
}

// generateThumbnail generates a thumbnail for the video
func (vp *VideoProcessor) generateThumbnail(videoData []byte) ([]byte, error) {
	// Create a temporary file for FFmpeg
	tempFile, err := os.CreateTemp("", "video_*.mp4")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())
	defer tempFile.Close()

	// Write video data to temp file
	if _, err := tempFile.Write(videoData); err != nil {
		return nil, fmt.Errorf("failed to write video data: %w", err)
	}
	tempFile.Close()

	// Create output file for thumbnail
	thumbnailFile, err := os.CreateTemp("", "thumb_*.jpg")
	if err != nil {
		return nil, fmt.Errorf("failed to create thumbnail file: %w", err)
	}
	defer os.Remove(thumbnailFile.Name())
	defer thumbnailFile.Close()

	// Run FFmpeg to generate thumbnail
	cmd := exec.Command("ffmpeg",
		"-i", tempFile.Name(),
		"-ss", strconv.Itoa(vp.thumbnailTime),
		"-vframes", "1",
		"-vf", fmt.Sprintf("scale=%d:%d", vp.thumbnailSize, vp.thumbnailSize*3/4), // 4:3 aspect ratio
		"-y", // Overwrite output file
		thumbnailFile.Name())

	err = cmd.Run()
	if err != nil {
		return nil, fmt.Errorf("failed to generate thumbnail: %w", err)
	}

	// Read thumbnail data
	thumbnailData, err := io.ReadAll(thumbnailFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read thumbnail data: %w", err)
	}

	return thumbnailData, nil
}

// optimizeVideo optimizes the video for web delivery
func (vp *VideoProcessor) optimizeVideo(videoData []byte) ([]byte, error) {
	// Create a temporary file for FFmpeg
	tempFile, err := os.CreateTemp("", "video_*.mp4")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())
	defer tempFile.Close()

	// Write video data to temp file
	if _, err := tempFile.Write(videoData); err != nil {
		return nil, fmt.Errorf("failed to write video data: %w", err)
	}
	tempFile.Close()

	// Create output file for optimized video
	optimizedFile, err := os.CreateTemp("", "optimized_*.mp4")
	if err != nil {
		return nil, fmt.Errorf("failed to create optimized file: %w", err)
	}
	defer os.Remove(optimizedFile.Name())
	defer optimizedFile.Close()

	// Run FFmpeg to optimize video
	cmd := exec.Command("ffmpeg",
		"-i", tempFile.Name(),
		"-c:v", "libx264",
		"-preset", "medium",
		"-crf", "23",
		"-c:a", "aac",
		"-b:a", "128k",
		"-movflags", "+faststart", // Enable fast start for web streaming
		"-y", // Overwrite output file
		optimizedFile.Name())

	err = cmd.Run()
	if err != nil {
		return nil, fmt.Errorf("failed to optimize video: %w", err)
	}

	// Read optimized video data
	optimizedData, err := io.ReadAll(optimizedFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read optimized video data: %w", err)
	}

	return optimizedData, nil
}

// getVideoFormat returns the video format based on filename
func (vp *VideoProcessor) getVideoFormat(filename string) string {
	ext := strings.ToLower(filepath.Ext(filename))
	switch ext {
	case ".mp4":
		return "mp4"
	case ".webm":
		return "webm"
	default:
		return "mp4"
	}
}

// VideoProcessingResult contains the results of video processing
type VideoProcessingResult struct {
	OriginalData  []byte
	OptimizedData []byte
	ThumbnailData []byte
	Metadata      map[string]interface{}
	Format        string
	MimeType      string
}

// GetThumbnailMimeType returns the MIME type for video thumbnails
func (vp *VideoProcessor) GetThumbnailMimeType() string {
	return "image/jpeg"
}

// GetThumbnailExtension returns the file extension for video thumbnails
func (vp *VideoProcessor) GetThumbnailExtension() string {
	return ".jpg"
}

// ValidateVideo validates that the file is a valid video
func (vp *VideoProcessor) ValidateVideo(reader io.Reader) error {
	// Read first 512 bytes for file type detection
	header := make([]byte, 512)
	n, err := reader.Read(header)
	if err != nil && err != io.EOF {
		return fmt.Errorf("failed to read file header: %w", err)
	}

	// Check if it's a valid video
	if !filetype.IsVideo(header[:n]) {
		return fmt.Errorf("file is not a valid video")
	}

	return nil
}

// GetVideoDuration returns the duration of a video without fully processing it
func (vp *VideoProcessor) GetVideoDuration(reader io.Reader) (time.Duration, error) {
	// This would require FFmpeg to get accurate duration
	// For now, return 0 to indicate duration is unknown
	return 0, fmt.Errorf("video duration detection not implemented")
}

// isFFmpegAvailable checks if FFmpeg is available on the system
func (vp *VideoProcessor) isFFmpegAvailable() bool {
	cmd := exec.Command("ffprobe", "-version")
	err := cmd.Run()
	return err == nil
}
