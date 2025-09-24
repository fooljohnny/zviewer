package processing

import (
	"bytes"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"strings"

	"github.com/disintegration/imaging"
	"github.com/h2non/filetype"
	"github.com/sirupsen/logrus"
)

// ImageProcessor handles image processing operations
type ImageProcessor struct {
	thumbnailSize int
}

// NewImageProcessor creates a new image processor
func NewImageProcessor(thumbnailSize int) *ImageProcessor {
	return &ImageProcessor{
		thumbnailSize: thumbnailSize,
	}
}

// ProcessImage processes an uploaded image file
func (ip *ImageProcessor) ProcessImage(reader io.Reader, filename string) (*ImageProcessingResult, error) {
	// Read the image data
	imageData, err := io.ReadAll(reader)
	if err != nil {
		return nil, fmt.Errorf("failed to read image data: %w", err)
	}

	// Validate file type
	fileType, err := filetype.Match(imageData)
	if err != nil {
		return nil, fmt.Errorf("failed to detect file type: %w", err)
	}

	if !filetype.IsImage(imageData) {
		return nil, fmt.Errorf("file is not a valid image")
	}

	// Decode the image
	img, format, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, fmt.Errorf("failed to decode image: %w", err)
	}

	// Extract metadata
	metadata := ip.extractImageMetadata(img, format)

	// Generate thumbnail
	thumbnailData, err := ip.generateThumbnail(img, format)
	if err != nil {
		logrus.Warnf("Failed to generate thumbnail: %v", err)
	}

	// Optimize image for web delivery
	optimizedData, err := ip.optimizeImage(img, format)
	if err != nil {
		logrus.Warnf("Failed to optimize image: %v", err)
		optimizedData = imageData // Use original if optimization fails
	}

	return &ImageProcessingResult{
		OriginalData:  imageData,
		OptimizedData: optimizedData,
		ThumbnailData: thumbnailData,
		Metadata:      metadata,
		Format:        format,
		MimeType:      fileType.MIME.Value,
	}, nil
}

// generateThumbnail generates a thumbnail for the image
func (ip *ImageProcessor) generateThumbnail(img image.Image, format string) ([]byte, error) {
	// Resize image to thumbnail size
	thumbnail := imaging.Fit(img, ip.thumbnailSize, ip.thumbnailSize, imaging.Lanczos)

	// Encode thumbnail as JPEG
	var buf bytes.Buffer
	err := jpeg.Encode(&buf, thumbnail, &jpeg.Options{Quality: 85})
	if err != nil {
		return nil, fmt.Errorf("failed to encode thumbnail: %w", err)
	}

	return buf.Bytes(), nil
}

// optimizeImage optimizes the image for web delivery
func (ip *ImageProcessor) optimizeImage(img image.Image, format string) ([]byte, error) {
	var buf bytes.Buffer

	switch strings.ToLower(format) {
	case "jpeg", "jpg":
		// Optimize JPEG
		err := jpeg.Encode(&buf, img, &jpeg.Options{Quality: 85})
		if err != nil {
			return nil, fmt.Errorf("failed to encode JPEG: %w", err)
		}
	case "png":
		// Optimize PNG
		encoder := &png.Encoder{
			CompressionLevel: png.BestCompression,
		}
		err := encoder.Encode(&buf, img)
		if err != nil {
			return nil, fmt.Errorf("failed to encode PNG: %w", err)
		}
	default:
		// For other formats, convert to JPEG
		err := jpeg.Encode(&buf, img, &jpeg.Options{Quality: 85})
		if err != nil {
			return nil, fmt.Errorf("failed to convert to JPEG: %w", err)
		}
	}

	return buf.Bytes(), nil
}

// extractImageMetadata extracts metadata from the image
func (ip *ImageProcessor) extractImageMetadata(img image.Image, format string) map[string]interface{} {
	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()

	metadata := map[string]interface{}{
		"width":  width,
		"height": height,
		"format": format,
	}

	// Calculate aspect ratio
	if height > 0 {
		metadata["aspect_ratio"] = float64(width) / float64(height)
	}

	// Determine orientation
	if width > height {
		metadata["orientation"] = "landscape"
	} else if height > width {
		metadata["orientation"] = "portrait"
	} else {
		metadata["orientation"] = "square"
	}

	return metadata
}

// ConvertToWebP converts an image to WebP format
func (ip *ImageProcessor) ConvertToWebP(img image.Image) ([]byte, error) {
	// Note: This would require a WebP encoder library
	// For now, we'll return an error indicating WebP is not supported
	return nil, fmt.Errorf("WebP conversion not implemented")
}

// ResizeImage resizes an image to specified dimensions
func (ip *ImageProcessor) ResizeImage(img image.Image, width, height int) image.Image {
	return imaging.Resize(img, width, height, imaging.Lanczos)
}

// CropImage crops an image to specified dimensions
func (ip *ImageProcessor) CropImage(img image.Image, width, height int) image.Image {
	return imaging.CropCenter(img, width, height)
}

// ImageProcessingResult contains the results of image processing
type ImageProcessingResult struct {
	OriginalData  []byte
	OptimizedData []byte
	ThumbnailData []byte
	Metadata      map[string]interface{}
	Format        string
	MimeType      string
}

// GetThumbnailMimeType returns the MIME type for thumbnails
func (ip *ImageProcessor) GetThumbnailMimeType() string {
	return "image/jpeg"
}

// GetThumbnailExtension returns the file extension for thumbnails
func (ip *ImageProcessor) GetThumbnailExtension() string {
	return ".jpg"
}

// ValidateImage validates that the file is a valid image
func (ip *ImageProcessor) ValidateImage(reader io.Reader) error {
	// Read first 512 bytes for file type detection
	header := make([]byte, 512)
	n, err := reader.Read(header)
	if err != nil && err != io.EOF {
		return fmt.Errorf("failed to read file header: %w", err)
	}

	// Check if it's a valid image
	if !filetype.IsImage(header[:n]) {
		return fmt.Errorf("file is not a valid image")
	}

	return nil
}

// GetImageDimensions returns the dimensions of an image without fully decoding it
func (ip *ImageProcessor) GetImageDimensions(reader io.Reader) (width, height int, err error) {
	// Read the image data
	imageData, err := io.ReadAll(reader)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to read image data: %w", err)
	}

	// Decode image config (faster than full decode)
	config, format, err := image.DecodeConfig(bytes.NewReader(imageData))
	if err != nil {
		return 0, 0, fmt.Errorf("failed to decode image config: %w", err)
	}

	logrus.Debugf("Image dimensions: %dx%d, format: %s", config.Width, config.Height, format)
	return config.Width, config.Height, nil
}
