package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// TestAlbumAPI tests the album API endpoints
func main() {
	baseURL := "http://localhost:8080"

	// Test data
	loginData := map[string]string{
		"email":    "admin@zviewer.local",
		"password": "admin123",
	}

	createAlbumData := map[string]interface{}{
		"title":       "Test Album",
		"description": "This is a test album",
		"imageIds":    []string{"test-image-1", "test-image-2"},
		"tags":        []string{"test", "demo"},
		"isPublic":    true,
	}

	// Step 1: Login to get token
	fmt.Println("🔐 Logging in...")
	token, err := login(baseURL, loginData)
	if err != nil {
		fmt.Printf("❌ Login failed: %v\n", err)
		return
	}
	fmt.Printf("✅ Login successful, token: %s\n", token[:20]+"...")

	// Step 2: Create album
	fmt.Println("\n📸 Creating album...")
	albumID, err := createAlbum(baseURL, token, createAlbumData)
	if err != nil {
		fmt.Printf("❌ Create album failed: %v\n", err)
		return
	}
	fmt.Printf("✅ Album created with ID: %s\n", albumID)

	// Step 3: Get album
	fmt.Println("\n🔍 Getting album...")
	err = getAlbum(baseURL, token, albumID)
	if err != nil {
		fmt.Printf("❌ Get album failed: %v\n", err)
		return
	}
	fmt.Println("✅ Album retrieved successfully")

	// Step 4: List albums
	fmt.Println("\n📋 Listing albums...")
	err = listAlbums(baseURL, token)
	if err != nil {
		fmt.Printf("❌ List albums failed: %v\n", err)
		return
	}
	fmt.Println("✅ Albums listed successfully")

	// Step 5: Update album
	fmt.Println("\n✏️ Updating album...")
	updateData := map[string]interface{}{
		"title":       "Updated Test Album",
		"description": "This is an updated test album",
		"isPublic":    false,
	}
	err = updateAlbum(baseURL, token, albumID, updateData)
	if err != nil {
		fmt.Printf("❌ Update album failed: %v\n", err)
		return
	}
	fmt.Println("✅ Album updated successfully")

	// Step 6: Delete album
	fmt.Println("\n🗑️ Deleting album...")
	err = deleteAlbum(baseURL, token, albumID)
	if err != nil {
		fmt.Printf("❌ Delete album failed: %v\n", err)
		return
	}
	fmt.Println("✅ Album deleted successfully")

	fmt.Println("\n🎉 All tests passed!")
}

func login(baseURL string, data map[string]string) (string, error) {
	jsonData, _ := json.Marshal(data)
	resp, err := http.Post(baseURL+"/api/auth/login", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("login failed: %s", string(body))
	}

	var result map[string]interface{}
	json.Unmarshal(body, &result)

	return result["token"].(string), nil
}

func createAlbum(baseURL, token string, data map[string]interface{}) (string, error) {
	jsonData, _ := json.Marshal(data)
	req, _ := http.NewRequest("POST", baseURL+"/api/admin/albums", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != 201 {
		return "", fmt.Errorf("create album failed: %s", string(body))
	}

	var result map[string]interface{}
	json.Unmarshal(body, &result)

	album := result["album"].(map[string]interface{})
	return album["id"].(string), nil
}

func getAlbum(baseURL, token, albumID string) error {
	req, _ := http.NewRequest("GET", baseURL+"/api/admin/albums/"+albumID, nil)
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("get album failed: %s", string(body))
	}

	return nil
}

func listAlbums(baseURL, token string) error {
	req, _ := http.NewRequest("GET", baseURL+"/api/admin/albums", nil)
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("list albums failed: %s", string(body))
	}

	return nil
}

func updateAlbum(baseURL, token, albumID string, data map[string]interface{}) error {
	jsonData, _ := json.Marshal(data)
	req, _ := http.NewRequest("PUT", baseURL+"/api/admin/albums/"+albumID, bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("update album failed: %s", string(body))
	}

	return nil
}

func deleteAlbum(baseURL, token, albumID string) error {
	req, _ := http.NewRequest("DELETE", baseURL+"/api/admin/albums/"+albumID, nil)
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("delete album failed: %s", string(body))
	}

	return nil
}
