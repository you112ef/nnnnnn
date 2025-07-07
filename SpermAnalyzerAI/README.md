# 🔬 Sperm Analyzer AI

<div align="center">

![Sperm Analyzer AI](https://img.shields.io/badge/Sperm%20Analyzer-AI-blue?style=for-the-badge&logo=android)
![Flutter](https://img.shields.io/badge/Flutter-3.16.0-blue?style=for-the-badge&logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-Latest-green?style=for-the-badge&logo=fastapi)
![YOLOv8](https://img.shields.io/badge/YOLOv8-AI-orange?style=for-the-badge)

**تطبيق متقدم لتحليل الحيوانات المنوية باستخدام الذكاء الاصطناعي**

*Advanced Sperm Analysis Application with Artificial Intelligence*

[📱 Download APK](#-downloads) • [🚀 Quick Start](#-quick-start) • [📖 Documentation](#-documentation) • [🤝 Contributing](#-contributing)

</div>

---

## 🌟 Overview | نظرة عامة

**Sperm Analyzer AI** is a comprehensive mobile application that leverages artificial intelligence to provide accurate and detailed sperm analysis. Built with modern technologies including Flutter, FastAPI, and YOLOv8, this application offers professional-grade analysis capabilities with an intuitive user interface supporting both Arabic and English languages.

**تطبيق Sperm Analyzer AI** هو تطبيق جوال شامل يستخدم الذكاء الاصطناعي لتوفير تحليل دقيق ومفصل للحيوانات المنوية. تم بناؤه بتقنيات حديثة تشمل Flutter و FastAPI و YOLOv8، ويوفر إمكانيات تحليل بمستوى احترافي مع واجهة مستخدم بديهية تدعم اللغتين العربية والإنجليزية.

## ✨ Key Features | الميزات الرئيسية

### 🔬 AI-Powered Analysis | التحليل بالذكاء الاصطناعي
- **YOLOv8 + DeepSORT**: Advanced object detection and tracking
- **Real-time Processing**: Live camera analysis capabilities
- **High Accuracy**: Professional-grade analysis results
- **CASA Parameters**: Complete Computer-Assisted Sperm Analysis

### 📱 Mobile Application | التطبيق الجوال
- **Cross-Platform**: Android (iOS ready)
- **Modern UI**: Professional dark theme design
- **Multilingual**: Full Arabic and English support with RTL
- **Responsive**: Optimized for all screen sizes

### 📊 Data Visualization | تصور البيانات
- **Interactive Charts**: Multiple chart types (Line, Bar, Pie, Radar)
- **Real-time Updates**: Live data visualization
- **Export Options**: Multiple export formats (CSV, JSON, PDF)
- **Professional Reports**: Detailed medical reports

### 🎯 Analysis Capabilities | قدرات التحليل
- **Sperm Count**: Accurate counting algorithms
- **Motility Analysis**: Movement pattern recognition
- **Morphology Assessment**: Shape and structure evaluation
- **Velocity Measurements**: Speed and direction analysis

## 🏗️ Architecture | المعمارية

```
SpermAnalyzerAI/
├── 📱 mobile-app/          # Flutter Application
│   ├── lib/
│   │   ├── screens/        # UI Screens
│   │   ├── services/       # Business Logic
│   │   ├── models/         # Data Models
│   │   └── widgets/        # Reusable Components
│   └── assets/             # Resources & Assets
├── 🚀 backend-api/         # FastAPI Backend
│   ├── app/
│   │   ├── routes/         # API Endpoints
│   │   ├── services/       # Core Services
│   │   ├── models/         # Database Models
│   │   └── utils/          # Utilities
│   └── requirements.txt    # Dependencies
├── 🤖 model/               # AI Model & Training
│   ├── training_scripts/   # Training Code
│   └── requirements.txt    # ML Dependencies
└── ⚙️ .github/             # CI/CD & Automation
    └── workflows/          # GitHub Actions
```

## 🚀 Quick Start | البداية السريعة

### Prerequisites | المتطلبات الأساسية

- **Flutter**: 3.16.0 or higher
- **Python**: 3.11 or higher
- **Java**: JDK 17 for Android builds
- **Android Studio**: For development and testing

### 📥 Installation | التثبيت

#### 1. Clone Repository | استنساخ المستودع
```bash
git clone https://github.com/yourusername/SpermAnalyzerAI.git
cd SpermAnalyzerAI
```

#### 2. Setup Mobile App | إعداد التطبيق الجوال
```bash
cd mobile-app
flutter pub get
flutter run
```

#### 3. Setup Backend API | إعداد الخادم الخلفي
```bash
cd backend-api
pip install -r requirements.txt
uvicorn app.main:app --reload
```

#### 4. Setup AI Model | إعداد نموذج الذكاء الاصطناعي
```bash
cd model
pip install -r requirements.txt
python training_scripts/run_training.py
```

## 📱 Mobile App Features | ميزات التطبيق الجوال

### 🖥️ User Interface | واجهة المستخدم
- **Professional Design**: Modern dark theme with blue accents
- **Arabic Support**: Complete RTL (Right-to-Left) layout support
- **Responsive Layout**: Optimized for phones and tablets
- **Accessibility**: WCAG compliant interface elements

### 📷 Camera Integration | دمج الكاميرا
- **Live Preview**: Real-time camera feed
- **Photo Capture**: High-quality image capture
- **Video Recording**: Video analysis capabilities
- **Flash Control**: Automatic and manual flash settings

### 📈 Data Analysis | تحليل البيانات
- **Real-time Processing**: Instant analysis results
- **Historical Data**: Previous analysis storage
- **Comparison Tools**: Result comparison features
- **Export Options**: Multiple sharing and export formats

## 🔧 Backend API | واجهة برمجة التطبيقات

### 🛣️ Endpoints | نقاط النهاية

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/analyze` | Upload and analyze samples |
| `GET` | `/results/{id}` | Retrieve analysis results |
| `GET` | `/results` | List all results |
| `GET` | `/export/{format}` | Export results in various formats |
| `GET` | `/status` | System health check |
| `GET` | `/metrics` | Performance metrics |

### 🔒 Authentication | المصادقة
- **API Keys**: Secure API access
- **Rate Limiting**: Request throttling
- **CORS Support**: Cross-origin resource sharing
- **Security Headers**: Enhanced security measures

## 🤖 AI Model Details | تفاصيل نموذج الذكاء الاصطناعي

### 🎯 YOLOv8 Integration | دمج YOLOv8
- **Object Detection**: Sperm cell identification
- **Real-time Processing**: GPU-accelerated inference
- **High Accuracy**: >95% detection accuracy
- **Custom Training**: Domain-specific model training

### 🔄 DeepSORT Tracking | تتبع DeepSORT
- **Multi-object Tracking**: Individual sperm tracking
- **Motion Analysis**: Movement pattern recognition
- **Velocity Calculation**: Speed and direction measurements
- **Path Reconstruction**: Complete trajectory analysis

### 📊 CASA Parameters | معاملات CASA

| Parameter | Description | Normal Range |
|-----------|-------------|--------------|
| **VCL** | Curvilinear Velocity | 25-45 μm/s |
| **VSL** | Straight Line Velocity | 20-35 μm/s |
| **VAP** | Average Path Velocity | 22-40 μm/s |
| **LIN** | Linearity | 50-85% |
| **STR** | Straightness | 60-90% |
| **WOB** | Wobble | 50-80% |
| **MOT** | Motility | 40-100% |
| **ALH** | Amplitude of Lateral Head | 2-7 μm |
| **BCF** | Beat Cross Frequency | 10-30 Hz |

## 📊 Chart Visualizations | تصورات الرسوم البيانية

### 📈 Available Charts | الرسوم البيانية المتاحة
- **Line Charts**: Velocity over time
- **Bar Charts**: CASA parameter comparisons
- **Pie Charts**: Morphology distribution
- **Radar Charts**: Multi-parameter overview

### 💾 Export Options | خيارات التصدير
- **CSV**: Spreadsheet-compatible data
- **JSON**: Structured data format
- **PDF**: Professional reports
- **Image**: Chart screenshots

## 🌍 Localization | التوطين

### 🔤 Supported Languages | اللغات المدعومة
- **Arabic (العربية)**: Complete RTL support
- **English**: Full interface translation

### 🔄 RTL Support | دعم RTL
- **Layout Direction**: Automatic layout mirroring
- **Text Direction**: Proper text rendering
- **Icon Positioning**: Context-aware icon placement
- **Navigation**: RTL-compatible navigation patterns

## 🧪 Testing | الاختبار

### 🔍 Test Coverage | تغطية الاختبارات
- **Unit Tests**: Individual component testing
- **Integration Tests**: API endpoint testing
- **Widget Tests**: UI component testing
- **E2E Tests**: Complete workflow testing

### ▶️ Running Tests | تشغيل الاختبارات
```bash
# Flutter tests
cd mobile-app
flutter test --coverage

# Backend tests
cd backend-api
pytest --cov=app

# Model tests
cd model
python -m pytest training_scripts/
```

## 🚀 Deployment | النشر

### 📦 Build APK | بناء APK
```bash
cd mobile-app
flutter build apk --release
```

### 🐳 Docker Deployment | نشر Docker
```bash
cd backend-api
docker build -t sperm-analyzer-api .
docker run -p 8000:8000 sperm-analyzer-api
```

### ☁️ Cloud Deployment | النشر السحابي
- **Google Cloud**: App Engine deployment ready
- **AWS**: Elastic Beanstalk compatible
- **Azure**: Container deployment support

## 📥 Downloads | التحميلات

### 📱 Mobile Application | التطبيق الجوال

| Platform | Download | Version | Size |
|----------|----------|---------|------|
| 🤖 **Android APK** | [📱 Download](releases/latest) | v1.0.0 | ~25 MB |
| 📦 **Android AAB** | [📦 Download](releases/latest) | v1.0.0 | ~20 MB |

### 🔧 Development Tools | أدوات التطوير
- **Source Code**: Available on GitHub
- **Documentation**: Comprehensive guides included
- **Training Data**: Sample datasets provided

## 📖 Documentation | التوثيق

### 📚 Available Guides | الأدلة المتاحة
- [🚀 **Quick Start Guide**](docs/quick-start.md)
- [📱 **Mobile App Guide**](mobile-app/README.md)
- [🚀 **Backend API Guide**](backend-api/README.md)
- [🤖 **AI Model Guide**](model/README.md)
- [🌍 **Localization Guide**](mobile-app/RTL_SUPPORT.md)

### 🔗 API Documentation | توثيق API
- **Interactive Docs**: Available at `/docs` endpoint
- **OpenAPI Spec**: Complete API specification
- **Postman Collection**: Ready-to-use API collection

## 🤝 Contributing | المساهمة

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### 🐛 Reporting Issues | الإبلاغ عن المشاكل
- [🐛 **Bug Reports**](.github/ISSUE_TEMPLATE/bug_report.yml)
- [✨ **Feature Requests**](.github/ISSUE_TEMPLATE/feature_request.yml)

### 💻 Development Setup | إعداد التطوير
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📜 License | الترخيص

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author | المؤلف

**يوسف الشتيوي (Youssef Alshtiwi)**
- 📧 Email: youssef.alshtiwi@example.com
- 🌐 GitHub: [@youssef-alshtiwi](https://github.com/youssef-alshtiwi)
- 💼 LinkedIn: [Youssef Alshtiwi](https://linkedin.com/in/youssef-alshtiwi)

## 🙏 Acknowledgments | الشكر والتقدير

- **YOLOv8**: Ultralytics for the excellent object detection framework
- **Flutter**: Google for the amazing cross-platform framework
- **FastAPI**: Sebastian Ramirez for the high-performance web framework
- **DeepSORT**: The original DeepSORT implementation team

## 📈 Project Status | حالة المشروع

![Build Status](https://github.com/username/SpermAnalyzerAI/workflows/CI/badge.svg)
![Coverage](https://codecov.io/gh/username/SpermAnalyzerAI/branch/main/graph/badge.svg)
![License](https://img.shields.io/github/license/username/SpermAnalyzerAI)
![Version](https://img.shields.io/github/v/release/username/SpermAnalyzerAI)

## ⚠️ Disclaimer | إخلاء المسؤولية

**English**: This application is designed for research and educational purposes. It should not be used as a replacement for professional medical diagnosis or treatment. Always consult with qualified healthcare professionals for medical advice.

**العربية**: هذا التطبيق مصمم لأغراض البحث والتعليم. لا ينبغي استخدامه كبديل للتشخيص الطبي المهني أو العلاج. استشر دائماً أخصائيي الرعاية الصحية المؤهلين للحصول على المشورة الطبية.

---

<div align="center">

**Made with ❤️ for advancing reproductive health research**

**صُنع بـ ❤️ لتطوير أبحاث الصحة الإنجابية**

</div>