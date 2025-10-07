package image

import (
	"fmt"
	"image"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"os"
)

// GetImageDimensions returns the width and height of an image file
func GetImageDimensions(filePath string) (width, height int, err error) {
	// Check if file exists first
	fileInfo, err := os.Stat(filePath)
	if err != nil {
		return 0, 0, fmt.Errorf("file does not exist: %w", err)
	}

	// Log file info for debugging
	fmt.Printf("🔍 ImageUtils: Attempting to extract dimensions from file: %s\n", filePath)
	fmt.Printf("🔍 ImageUtils: File size: %d bytes\n", fileInfo.Size())
	fmt.Printf("🔍 ImageUtils: File mode: %s\n", fileInfo.Mode())

	file, err := os.Open(filePath)
	if err != nil {
		fmt.Printf("❌ ImageUtils: Failed to open file: %v\n", err)
		return 0, 0, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	fmt.Printf("🔍 ImageUtils: File opened successfully, attempting to decode config\n")

	config, format, err := image.DecodeConfig(file)
	if err != nil {
		fmt.Printf("❌ ImageUtils: Failed to decode image config: %v\n", err)
		return 0, 0, fmt.Errorf("failed to decode image config: %w", err)
	}

	fmt.Printf("✅ ImageUtils: Successfully extracted dimensions - Width: %d, Height: %d, Format: %s\n",
		config.Width, config.Height, format)

	return config.Width, config.Height, nil
}
