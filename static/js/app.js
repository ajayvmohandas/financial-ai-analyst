// Frontend JavaScript for IDP Financial Analyst

class FinancialAnalystApp {
    constructor() {
        this.currentSessionId = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadDocuments();
        this.checkHealth();
    }

    setupEventListeners() {
        // Upload form
        document.getElementById('uploadForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.uploadDocument();
        });

        // Chat form
        document.getElementById('chatForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.askQuestion();
        });

        // Sample questions
        document.querySelectorAll('.sample-question').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const question = e.target.textContent;
                document.getElementById('questionInput').value = question;
                this.askQuestion();
            });
        });

        // File input change
        document.getElementById('documentFile').addEventListener('change', (e) => {
            this.validateFile(e.target.files[0]);
        });
    }

    validateFile(file) {
        if (!file) return true;

        const allowedTypes = ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 
                             'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/plain'];
        const maxSize = 50 * 1024 * 1024; // 50MB

        if (!allowedTypes.includes(file.type)) {
            this.showAlert('danger', 'Invalid file type. Please upload PDF, DOCX, XLSX, or TXT files.');
            return false;
        }

        if (file.size > maxSize) {
            this.showAlert('danger', 'File size too large. Maximum size is 50MB.');
            return false;
        }

        return true;
    }

    async uploadDocument() {
        const fileInput = document.getElementById('documentFile');
        const file = fileInput.files[0];

        if (!file) {
            this.showAlert('danger', 'Please select a file to upload.');
            return;
        }

        if (!this.validateFile(file)) {
            return;
        }

        const formData = new FormData();
        formData.append('file', file);

        // Show progress
        document.getElementById('uploadProgress').style.display = 'block';
        document.getElementById('uploadBtn').disabled = true;

        try {
            const response = await fetch('/upload', {
                method: 'POST',
                body: formData
            });

            const result = await response.json();

            if (response.ok) {
                this.showAlert('success', result.message);
                this.loadDocuments();
                fileInput.value = '';
            } else {
                this.showAlert('danger', result.detail || 'Upload failed');
            }
        } catch (error) {
            this.showAlert('danger', 'Upload failed: ' + error.message);
        } finally {
            document.getElementById('uploadProgress').style.display = 'none';
            document.getElementById('uploadBtn').disabled = false;
        }
    }

    async askQuestion() {
        const questionInput = document.getElementById('questionInput');
        const question = questionInput.value.trim();

        if (!question) {
            this.showAlert('danger', 'Please enter a question.');
            return;
        }

        // Add user message to chat
        this.addMessage('user', question);
        questionInput.value = '';

        // Show loading
        document.getElementById('chatProgress').style.display = 'block';
        document.getElementById('askBtn').disabled = true;

        try {
            const response = await fetch('/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    question: question,
                    session_id: this.currentSessionId
                })
            });

            const result = await response.json();

            if (response.ok) {
                this.currentSessionId = result.session_id;
                this.updateSessionId(result.session_id);
                this.addMessage('assistant', result.answer, result.sources, result.company_identified);
            } else {
                this.addMessage('assistant', 'Sorry, I encountered an error: ' + (result.detail || 'Unknown error'));
            }
        } catch (error) {
            this.addMessage('assistant', 'Sorry, I encountered an error: ' + error.message);
        } finally {
            document.getElementById('chatProgress').style.display = 'none';
            document.getElementById('askBtn').disabled = false;
        }
    }

    addMessage(role, content, sources = [], company = null) {
        const chatMessages = document.getElementById('chatMessages');
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role} new`;

        let messageHTML = `<div class="message-content">${content}</div>`;

        if (company) {
            messageHTML += `<div class="company-badge">📊 ${company}</div>`;
        }

        if (sources && sources.length > 0) {
            messageHTML += `<div class="sources">
                <strong>Sources:</strong><br>
                ${sources.map(source => `• ${source}`).join('<br>')}
            </div>`;
        }

        messageDiv.innerHTML = messageHTML;
        chatMessages.appendChild(messageDiv);
        chatMessages.scrollTop = chatMessages.scrollHeight;

        // Remove animation class after animation completes
        setTimeout(() => {
            messageDiv.classList.remove('new');
        }, 300);
    }

    async loadDocuments() {
        try {
            const response = await fetch('/documents');
            const result = await response.json();

            if (response.ok) {
                this.displayDocuments(result.documents);
                document.getElementById('docCount').textContent = result.documents.length;
            }
        } catch (error) {
            console.error('Failed to load documents:', error);
        }
    }

    displayDocuments(documents) {
        const documentsList = document.getElementById('documentsList');

        if (!documents || documents.length === 0) {
            documentsList.innerHTML = '<p class="text-muted">No documents uploaded yet</p>';
            return;
        }

        documentsList.innerHTML = documents.map(doc => `
            <div class="document-item">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="document-name">
                            <i class="fas fa-file-alt me-2"></i>
                            ${doc.filename}
                        </div>
                        <div class="document-status">
                            Uploaded: ${new Date(doc.upload_time).toLocaleString()}
                        </div>
                    </div>
                    <div>
                        <span class="status-badge processed">Processed</span>
                    </div>
                </div>
            </div>
        `).join('');
    }

    async checkHealth() {
        try {
            const response = await fetch('/health');
            const health = await response.json();

            if (!response.ok || health.status !== 'healthy') {
                console.warn('System health check failed:', health);
            }
        } catch (error) {
            console.error('Health check failed:', error);
        }
    }

    updateSessionId(sessionId) {
        const sessionElement = document.getElementById('sessionId');
        if (sessionId) {
            sessionElement.textContent = sessionId.substring(0, 8) + '...';
        } else {
            sessionElement.textContent = 'New';
        }
    }

    showAlert(type, message) {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
        alertDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;

        // Insert at the top of the container
        const container = document.querySelector('.container');
        container.insertBefore(alertDiv, container.firstChild);

        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, 5000);

        // Scroll to top to show the alert
        window.scrollTo(0, 0);
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new FinancialAnalystApp();
});

// Add some utility functions
window.formatFileSize = function(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

window.formatTime = function(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString();
};
