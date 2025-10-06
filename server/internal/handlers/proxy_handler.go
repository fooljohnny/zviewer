package handlers

import (
	"io"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// ProxyHandler handles proxying requests to microservices
type ProxyHandler struct {
	mediaServiceURL string
	logger          *logrus.Logger
}

// NewProxyHandler creates a new proxy handler
func NewProxyHandler(mediaServiceURL string, logger *logrus.Logger) *ProxyHandler {
	return &ProxyHandler{
		mediaServiceURL: mediaServiceURL,
		logger:          logger,
	}
}

// ProxyToMediaService proxies requests to the media service
func (h *ProxyHandler) ProxyToMediaService(c *gin.Context) {
	// Parse the media service URL
	target, err := url.Parse(h.mediaServiceURL)
	if err != nil {
		h.logger.Errorf("Failed to parse media service URL: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// Create a reverse proxy
	proxy := httputil.NewSingleHostReverseProxy(target)

	// Modify the request
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host
		// Convert /api/media-proxy/* to /api/media/*
		// Remove the extra /media from the path since media service expects /api/media not /api/media/media
		req.URL.Path = strings.Replace(req.URL.Path, "/api/media-proxy/media", "/api/media", 1)
		req.Host = target.Host
		// Ensure query parameters are preserved
		req.URL.RawQuery = req.URL.Query().Encode()
	}

	// Handle errors
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		h.logger.Errorf("Proxy error: %v", err)
		w.WriteHeader(http.StatusBadGateway)
		io.WriteString(w, "Bad Gateway")
	}

	// Serve the request
	proxy.ServeHTTP(c.Writer, c.Request)
}
