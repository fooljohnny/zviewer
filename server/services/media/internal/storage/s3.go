package storage

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

// S3Storage implements the Storage interface for AWS S3
type S3Storage struct {
	client *s3.Client
	bucket string
	region string
}

// NewS3Storage creates a new S3 storage instance
func NewS3Storage(bucket, region, accessKey, secretKey string) (*S3Storage, error) {
	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(cfg)

	return &S3Storage{
		client: client,
		bucket: bucket,
		region: region,
	}, nil
}

// SaveFile saves a file to S3 storage
func (s3s *S3Storage) SaveFile(ctx context.Context, filePath string, reader io.Reader) error {
	_, err := s3s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(s3s.bucket),
		Key:    aws.String(filePath),
		Body:   reader,
		ACL:    types.ObjectCannedACLPrivate,
	})

	if err != nil {
		return fmt.Errorf("failed to upload file to S3: %w", err)
	}

	return nil
}

// SaveFileFromBytes saves a file from byte data to S3 storage
func (s3s *S3Storage) SaveFileFromBytes(ctx context.Context, filePath string, data []byte) error {
	_, err := s3s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(s3s.bucket),
		Key:    aws.String(filePath),
		Body:   strings.NewReader(string(data)),
		ACL:    types.ObjectCannedACLPrivate,
	})

	if err != nil {
		return fmt.Errorf("failed to upload file to S3: %w", err)
	}

	return nil
}

// GetFile retrieves a file from S3 storage
func (s3s *S3Storage) GetFile(ctx context.Context, filePath string) (io.ReadCloser, error) {
	result, err := s3s.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s3s.bucket),
		Key:    aws.String(filePath),
	})

	if err != nil {
		return nil, fmt.Errorf("failed to get file from S3: %w", err)
	}

	return result.Body, nil
}

// DeleteFile removes a file from S3 storage
func (s3s *S3Storage) DeleteFile(ctx context.Context, filePath string) error {
	_, err := s3s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s3s.bucket),
		Key:    aws.String(filePath),
	})

	if err != nil {
		return fmt.Errorf("failed to delete file from S3: %w", err)
	}

	return nil
}

// FileExists checks if a file exists in S3 storage
func (s3s *S3Storage) FileExists(ctx context.Context, filePath string) (bool, error) {
	_, err := s3s.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(s3s.bucket),
		Key:    aws.String(filePath),
	})

	if err != nil {
		var notFound *types.NotFound
		if errors.As(err, &notFound) {
			return false, nil
		}
		return false, fmt.Errorf("failed to check file existence: %w", err)
	}

	return true, nil
}

// GetFileSize returns the size of a file in S3 storage
func (s3s *S3Storage) GetFileSize(ctx context.Context, filePath string) (int64, error) {
	result, err := s3s.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(s3s.bucket),
		Key:    aws.String(filePath),
	})

	if err != nil {
		return 0, fmt.Errorf("failed to get file size: %w", err)
	}

	return *result.ContentLength, nil
}

// GetFileURL returns a URL for accessing the file
func (s3s *S3Storage) GetFileURL(ctx context.Context, filePath string) (string, error) {
	// Generate a presigned URL for private access
	presigner := s3.NewPresignClient(s3s.client)

	request, err := presigner.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s3s.bucket),
		Key:    aws.String(filePath),
	}, func(opts *s3.PresignOptions) {
		opts.Expires = 3600 // 1 hour
	})

	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return request.URL, nil
}
