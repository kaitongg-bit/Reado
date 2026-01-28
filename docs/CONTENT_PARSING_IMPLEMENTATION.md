# QuickPM Content Parsing Implementation

## 📋 Overview

This document describes the implementation of content parsing functionality in QuickPM, inspired by the `open-notebook` project's approach to multi-source content extraction. The feature is **integrated into the existing `AddMaterialModal`**, not as a separate page.

## 🎯 Goal

Enable users to import learning materials from various sources (URLs, text) and automatically generate knowledge cards using Gemini AI.

---

## 🏗️ Architecture

### Reference: open-notebook

The `open-notebook` project uses:
- **content-core** (Python library) - Extracts content from URLs, PDFs, videos, audio files
- **LangGraph** - Processing pipeline for content transformation
- **async processing** - Background job queuing for heavy operations

### QuickPM Implementation

Since QuickPM is a **Flutter** application, we adapted the architecture:

```
┌────────────────────────────────────────────────────────────────┐
│                    QuickPM Flutter App                          │
├────────────────────────────────────────────────────────────────┤
│  AddMaterialModal (Integrated UI)                               │
│  ├── Tab 1: 文本导入 (Text Import)                               │
│  │   ├── 直接导入 - Local Markdown parsing                      │
│  │   └── AI 智能拆解 - Gemini AI generation                     │
│  └── Tab 2: 多模态 (AI)                                          │
│      ├── URL 提取 - Jina Reader AI extraction                   │
│      └── AI 智能拆解 - Gemini AI generation                     │
└─────────────────────┬──────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────────┐
│           ContentExtractionService                              │
├────────────────────────────────────────────────────────────────┤
│  extractFromUrl()   → Jina Reader AI API                       │
│  extractFromText()  → Direct text processing                   │
│  generateKnowledgeCards() → Gemini AI                          │
└─────────────────────┬──────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────────┐
│           Gemini 2.0 Flash (AI Generation)                     │
├────────────────────────────────────────────────────────────────┤
│  • Analyzes extracted content                                  │
│  • Generates 2-8 knowledge cards                               │
│  • Creates flashcards for each card                            │
│  • Returns structured JSON                                     │
└────────────────────────────────────────────────────────────────┘
```

---

## 📁 Files Modified/Created

### 1. Content Extraction Service (NEW)
**Path:** `lib/data/services/content_extraction_service.dart`

Core service that handles:
- URL content extraction via Jina Reader AI
- Text content processing
- Knowledge card generation using Gemini AI

**Key Methods:**
```dart
// Extract content from URL
static Future<ExtractionResult> extractFromUrl(String url)

// Process text directly
static ExtractionResult extractFromText(String text, {String? title})

// Generate knowledge cards from extracted content
static Future<List<FeedItem>> generateKnowledgeCards(
  ExtractionResult extraction,
  {required String moduleId}
)

// One-click processing
static Future<List<FeedItem>> processUrl(String url, {required String moduleId})
static Future<List<FeedItem>> processText(String text, {required String moduleId})
```

### 2. AddMaterialModal (MODIFIED)
**Path:** `lib/features/lab/presentation/add_material_modal.dart`

Enhanced with:
- **New URL extraction method:** `_extractFromUrl()`
- **New state variables:** `_urlController`, `_isExtractingUrl`, `_urlError`
- **Revamped "多模态 (AI)" tab:** Now has a fully functional URL input interface

**Tab Structure:**
| Tab | Features |
|-----|----------|
| 文本导入 | Paste text + Local parsing or AI generation |
| 多模态 (AI) | URL input + AI-powered content extraction |

---

## 🔧 Integration Points

The AddMaterialModal is opened from:
1. **Home Page:** Via the "+" button on each Knowledge Space card
2. **Learning Page:** Via the add material action

All generated content is:
- Saved to Firestore under the user's custom items
- Added to the in-memory FeedProvider for immediate display

---

## 📚 Supported Sources

### Currently Supported
| Source Type | Method | Tab |
|------------|--------|-----|
| Raw Text | Direct processing | 文本导入 |
| Markdown | Local parsing | 文本导入 |
| Web URLs | Jina Reader AI | 多模态 (AI) |

### Planned (Future)
| Source Type | Method | Notes |
|-------------|--------|-------|
| YouTube | Whisper API | Auto-transcription |
| PDF | Cloud Function | Requires backend |
| Audio/Video | Whisper API | Local files |

---

## 🎨 UI Features

### 多模态 (AI) Tab
- Gradient header with link icon
- URL input field with clear button
- Error display for invalid URLs
- Loading state during extraction
- "Supported Sources" section with chips
- Review state same as text import (for consistency)

---

## 🚀 Usage

### From URL (多模态 Tab)
1. Open AddMaterialModal (click "+" on any Knowledge Space)
2. Select "多模态 (AI)" tab  
3. Paste a web link (e.g., blog post, article)
4. Tap "提取并生成知识卡片"
5. Wait 10-30 seconds for extraction + AI generation
6. Review generated cards
7. Click "确认并保存"

### From Text (文本导入 Tab)
1. Open AddMaterialModal
2. Select "文本导入" tab
3. Paste your learning material (supports Markdown)
4. Choose:
   - "直接导入" - Parse locally by headers
   - "AI 智能拆解" - Use Gemini to generate cards
5. Review and save

---

## ⚙️ Configuration

### API Key Setup
The service uses `ApiConfig.getApiKey()` which checks:
1. `--dart-define=GEMINI_API_KEY=xxx` (development)
2. `DEFAULT_GEMINI_KEY` environment variable (fallback)
3. User-provided key in profile (future)

### Running the App
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key_here
```

---

## 🔮 Future Enhancements

1. **PDF Support:** Add Cloud Function for PDF text extraction
2. **YouTube Integration:** Extract video transcripts
3. **File Upload:** Add file picker UI
4. **Progress Tracking:** Show extraction progress for large content
5. **OCR Support:** Extract text from images
