package handlers

import (
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"zviewer-media-service/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/sirupsen/logrus"
)

// WebSocketHandler handles WebSocket connections for upload progress
type WebSocketHandler struct {
	upgrader websocket.Upgrader
	clients  map[string]*websocket.Conn
	mu       sync.RWMutex
}

// NewWebSocketHandler creates a new WebSocket handler
func NewWebSocketHandler() *WebSocketHandler {
	return &WebSocketHandler{
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins for development
			},
		},
		clients: make(map[string]*websocket.Conn),
	}
}

// HandleWebSocket handles WebSocket connections for upload progress
func (h *WebSocketHandler) HandleWebSocket(c *gin.Context) {
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		logrus.Errorf("Failed to upgrade WebSocket connection: %v", err)
		return
	}
	defer conn.Close()

	// Get upload ID from query parameter
	uploadID := c.Query("uploadId")
	if uploadID == "" {
		conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseInvalidFramePayloadData, "uploadId required"))
		return
	}

	// Register client
	h.mu.Lock()
	h.clients[uploadID] = conn
	h.mu.Unlock()

	// Clean up on disconnect
	defer func() {
		h.mu.Lock()
		delete(h.clients, uploadID)
		h.mu.Unlock()
	}()

	// Keep connection alive
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logrus.Errorf("WebSocket error: %v", err)
			}
			break
		}
	}
}

// BroadcastProgress broadcasts upload progress to connected clients
func (h *WebSocketHandler) BroadcastProgress(uploadID string, progress *models.UploadProgress) {
	h.mu.RLock()
	conn, exists := h.clients[uploadID]
	h.mu.RUnlock()

	if !exists {
		return
	}

	message, err := json.Marshal(progress)
	if err != nil {
		logrus.Errorf("Failed to marshal progress: %v", err)
		return
	}

	if err := conn.WriteMessage(websocket.TextMessage, message); err != nil {
		logrus.Errorf("Failed to send progress message: %v", err)
		// Remove client on error
		h.mu.Lock()
		delete(h.clients, uploadID)
		h.mu.Unlock()
	}
}

// BroadcastError broadcasts an error message to connected clients
func (h *WebSocketHandler) BroadcastError(uploadID string, errorMsg string) {
	h.mu.RLock()
	conn, exists := h.clients[uploadID]
	h.mu.RUnlock()

	if !exists {
		return
	}

	errorResponse := map[string]interface{}{
		"type":    "error",
		"message": errorMsg,
		"time":    time.Now(),
	}

	message, err := json.Marshal(errorResponse)
	if err != nil {
		logrus.Errorf("Failed to marshal error message: %v", err)
		return
	}

	if err := conn.WriteMessage(websocket.TextMessage, message); err != nil {
		logrus.Errorf("Failed to send error message: %v", err)
		// Remove client on error
		h.mu.Lock()
		delete(h.clients, uploadID)
		h.mu.Unlock()
	}
}
