<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TransLingo - English-Chinese Translation Tool</title>
    <!-- Tailwind CSS v3 -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Font Awesome -->
    <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
    <!-- PDF.js for PDF processing -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.4.120/pdf.min.js"></script>
    <!-- Tailwind Configuration -->
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#1e40af',
                        secondary: '#3b82f6',
                        accent: '#60a5fa',
                        light: '#f3f4f6',
                        dark: '#1f2937'
                    },
                    fontFamily: {
                        sans: ['Inter', 'system-ui', 'sans-serif'],
                        serif: ['Georgia', 'Cambria', 'serif']
                    },
                    boxShadow: {
                        'custom': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
                        'custom-lg': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)'
                    }
                }
            }
        }
    </script>
    <style type="text/tailwindcss">
        @layer utilities {
            .content-auto {
                content-visibility: auto;
            }
            .text-shadow {
                text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
            }
            .bg-gradient-blue {
                background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
            }
            .transition-height {
                transition: height 0.3s ease;
            }
            .custom-scrollbar::-webkit-scrollbar {
                width: 6px;
            }
            .custom-scrollbar::-webkit-scrollbar-track {
                background: #f1f1f1;
            }
            .custom-scrollbar::-webkit-scrollbar-thumb {
                background: #c5c5c5;
                border-radius: 3px;
            }
            .custom-scrollbar::-webkit-scrollbar-thumb:hover {
                background: #a0a0a0;
            }
        }
    </style>
    <style>
        /* Custom styles */
        .translation-popup {
            position: absolute;
            background: white;
            border-radius: 8px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            padding: 12px;
            max-width: 300px;
            z-index: 50;
            display: none;
        }
        
        .text-selection {
            background-color: rgba(96, 165, 250, 0.3);
        }
        
        .resizable {
            resize: horizontal;
            overflow: auto;
        }
        
        .grip {
            width: 6px;
            cursor: col-resize;
            background-color: #e5e7eb;
            transition: background-color 0.2s;
        }
        
        .grip:hover {
            background-color: #3b82f6;
        }
        
        /* Animation for file upload */
        @keyframes pulse {
            0%, 100% {
                opacity: 1;
            }
            50% {
                opacity: 0.5;
            }
        }
        
        .animate-pulse {
            animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
        }
        
        /* Skeleton loading effect */
        .skeleton {
            background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
            background-size: 200% 100%;
            animation: skeleton-loading 1.5s infinite;
        }
        
        @keyframes skeleton-loading {
            0% {
                background-position: 200% 0;
            }
            100% {
                background-position: -200% 0;
            }
        }
    </style>
</head>
<body class="bg-gray-50 font-sans">
    <!-- Header/Navigation -->
    <header class="bg-white shadow-sm sticky top-0 z-40">
        <div class="container mx-auto px-4 py-3 flex items-center justify-between">
            <div class="flex items-center space-x-2">
                <img src="https://p3-flow-imagex-sign.byteimg.com/tos-cn-i-a9rns2rl98/rc/pc/super_tool/239a7aec67ee4d14ba3be3186f1a3abb~tplv-a9rns2rl98-image.image?rcl=20251203230602FF5F18236405B6B744D7&rk3s=8e244e95&rrcfp=f06b921b&x-expires=1767366402&x-signature=Go1NWwYa9%2F4YomWFBn3gPRE8x4M%3D" alt="TransLingo Logo" class="h-10 w-auto">
                <h1 class="text-xl font-bold text-primary hidden sm:block">TransLingo</h1>
            </div>
            
            <nav class="hidden md:flex space-x-6">
                <a href="#" class="text-primary font-medium hover:text-secondary transition-colors" id="nav-text">Text Translation</a>
                <a href="#" class="text-gray-600 font-medium hover:text-primary transition-colors" id="nav-file">File Translation</a>
                <a href="#" class="text-gray-600 font-medium hover:text-primary transition-colors" id="nav-help">Help</a>
            </nav>
            
            <div class="flex items-center space-x-4">
                <div class="relative">
                    <select id="translation-engine" class="appearance-none bg-gray-100 border border-gray-300 text-gray-700 py-2 px-4 pr-8 rounded-lg leading-tight focus:outline-none focus:bg-white focus:border-primary">
                        <option value="google">Google Translate</option>
                        <option value="deepl">DeepL</option>
                        <option value="baidu">Baidu Translate</option>
                    </select>
                    <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700">
                        <i class="fa fa-chevron-down text-xs"></i>
                    </div>
                </div>
                
                <button id="mobile-menu-button" class="md:hidden text-gray-600 hover:text-primary focus:outline-none">
                    <i class="fa fa-bars text-xl"></i>
                </button>
            </div>
        </div>
        
        <!-- Mobile menu -->
        <div id="mobile-menu" class="md:hidden hidden bg-white border-t border-gray-200">
            <div class="container mx-auto px-4 py-2 space-y-2">
                <a href="#" class="block py-2 text-primary font-medium hover:text-secondary transition-colors" id="mobile-nav-text">Text Translation</a>
                <a href="#" class="block py-2 text-gray-600 font-medium hover:text-primary transition-colors" id="mobile-nav-file">File Translation</a>
                <a href="#" class="block py-2 text-gray-600 font-medium hover:text-primary transition-colors" id="mobile-nav-help">Help</a>
            </div>
        </div>
    </header>

    <!-- Hero Section -->
    <section class="bg-gradient-blue text-white py-12 md:py-20">
        <div class="container mx-auto px-4 text-center">
            <h1 class="text-3xl md:text-5xl font-bold mb-4 text-shadow">English-Chinese Translation Tool</h1>
            <p class="text-lg md:text-xl mb-8 max-w-3xl mx-auto">Effortlessly translate English texts and documents to Chinese with just a click. Enhance your reading experience with our intuitive translation tool.</p>
            <div class="flex flex-col sm:flex-row justify-center gap-4">
                <button id="start-text-translation" class="bg-white text-primary font-medium py-3 px-6 rounded-lg shadow-lg hover:shadow-xl transition-all transform hover:-translate-y-1">
                    <i class="fa fa-language mr-2"></i> Start Text Translation
                </button>
                <button id="start-file-translation" class="bg-transparent border-2 border-white text-white font-medium py-3 px-6 rounded-lg hover:bg-white hover:text-primary transition-all transform hover:-translate-y-1">
                    <i class="fa fa-upload mr-2"></i> Upload Document
                </button>
            </div>
        </div>
    </section>

    <!-- Main Content Area -->
    <main class="container mx-auto px-4 py-8">
        <!-- Text Translation Section -->
        <section id="text-translation-section" class="mb-12">
            <div class="bg-white rounded-xl shadow-custom-lg overflow-hidden">
                <div class="flex flex-col md:flex-row h-[600px]">
                    <!-- Source Text Area -->
                    <div class="flex-1 flex flex-col border-r border-gray-200">
                        <div class="bg-gray-50 px-4 py-3 border-b border-gray-200 flex justify-between items-center">
                            <div class="flex items-center">
                                <span class="text-sm font-medium text-gray-500 mr-2">Source Language:</span>
                                <select id="source-language" class="bg-white border border-gray-300 text-gray-700 py-1 px-3 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary">
                                    <option value="en">English</option>
                                    <option value="zh">Chinese</option>
                                    <option value="auto">Auto-detect</option>
                                </select>
                            </div>
                            <div class="flex space-x-2">
                                <button id="clear-source" class="text-gray-500 hover:text-red-500 p-1 rounded-md hover:bg-gray-200 transition-colors">
                                    <i class="fa fa-trash-o"></i>
                                </button>
                                <button id="paste-source" class="text-gray-500 hover:text-primary p-1 rounded-md hover:bg-gray-200 transition-colors">
                                    <i class="fa fa-paste"></i>
                                </button>
                                <button id="copy-source" class="text-gray-500 hover:text-primary p-1 rounded-md hover:bg-gray-200 transition-colors">
                                    <i class="fa fa-copy"></i>
                                </button>
                            </div>
                        </div>
                        <div class="flex-1 p-4 overflow-auto custom-scrollbar relative">
                            <textarea id="source-text" class="w-full h-full resize-none border-none focus:ring-0 text-gray-800 font-serif text-lg leading-relaxed" placeholder="Enter or paste text here..."></textarea>
                            <div id="source-text-placeholder" class="absolute inset-0 p-4 text-gray-400 font-serif text-lg leading-relaxed pointer-events-none flex items-center justify-center">
                                <div class="text-center">
                                    <i class="fa fa-file-text-o text-4xl mb-2"></i>
                                    <p>Enter or paste text here, or upload a document</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Resize grip -->
                    <div class="grip hidden md:block"></div>
                    
                    <!-- Translation Result Area -->
                    <div class="flex-1 flex flex-col">
                        <div class="bg-gray-50 px-4 py-3 border-b border-gray-200 flex justify-between items-center">
                            <div class="flex items-center">
                                <span class="text-sm font-medium text-gray-500 mr-2">Target Language:</span>
                                <select id="target-language" class="bg-white border border-gray-300 text-gray-700 py-1 px-3 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary">
                                    <option value="zh">Chinese</option>
                                    <option value="en">English</option>
                                </select>
                            </div>
                            <div class="flex space-x-2">
                                <button id="clear-target" class="text-gray-500 hover:text-red-500 p-1 rounded-md hover:bg-gray-200 transition-colors">
                                    <i class="fa fa-trash-o"></i>
                                </button>
                                <button id="copy-target" class="text-gray-500 hover:text-primary p-1 rounded-md hover:bg-gray-200 transition-colors">
                                    <i class="fa fa-copy"></i>
                                </button>
                                <button id="listen-target" class="text-gray-500 hover:text-primary p-1 rounded-md hover:bg-gray-200 transition-colors">
                                    <i class="fa fa-volume-up"></i>
                                </button>
                            </div>
                        </div>
                        <div class="flex-1 p-4 overflow-auto custom-scrollbar relative">
                            <div id="translation-result" class="w-full h-full text-gray-800 font-serif text-lg leading-relaxed"></div>
                            <div id="translation-placeholder" class="absolute inset-0 p-4 text-gray-400 font-serif text-lg leading-relaxed pointer-events-none flex items-center justify-center">
                                <div class="text-center">
                                    <i class="fa fa-language text-4xl mb-2"></i>
                                    <p>Translation will appear here</p>
                                </div>
                            </div>
                            <div id="translation-loading" class="absolute inset-0 p-4 hidden">
                                <div class="skeleton h-6 w-3/4 mb-4 rounded"></div>
                                <div class="skeleton h-6 w-full mb-4 rounded"></div>
                                <div class="skeleton h-6 w-5/6 mb-4 rounded"></div>
                                <div class="skeleton h-6 w-full mb-4 rounded"></div>
                                <div class="skeleton h-6 w-4/5 rounded"></div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Action Bar -->
                <div class="bg-gray-50 px-4 py-3 border-t border-gray-200 flex justify-between items-center">
                    <div class="flex items-center space-x-4">
                        <button id="swap-languages" class="text-primary hover:text-secondary transition-colors">
                            <i class="fa fa-exchange"></i>
                        </button>
                        <div class="text-sm text-gray-500">
                            <span id="character-count">0</span> characters
                        </div>
                    </div>
                    <button id="translate-button" class="bg-primary hover:bg-secondary text-white font-medium py-2 px-6 rounded-lg shadow hover:shadow-md transition-all transform hover:-translate-y-0.5">
                        <i class="fa fa-language mr-2"></i> Translate
                    </button>
                </div>
            </div>
        </div>
    </section>

    <!-- File Translation Section -->
    <section id="file-translation-section" class="mb-12 hidden">
        <div class="bg-white rounded-xl shadow-custom-lg overflow-hidden">
            <div class="p-6">
                <h2 class="text-xl font-bold text-gray-800 mb-6">Document Translation</h2>
                
                <div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center mb-6">
                    <input type="file" id="file-input" class="hidden" accept=".txt,.pdf,.doc,.docx">
                    <label for="file-input" class="cursor-pointer">
                        <div class="flex flex-col items-center justify-center">
                            <i class="fa fa-cloud-upload text-5xl text-gray-400 mb-4"></i>
                            <p class="text-lg text-gray-700 mb-2">Drag & drop your file here or click to browse</p>
                            <p class="text-sm text-gray-500 mb-4">Supported formats: TXT, PDF, DOC, DOCX (Max 10MB)</p>
                            <button class="bg-primary hover:bg-secondary text-white font-medium py-2 px-6 rounded-lg shadow hover:shadow-md transition-all">
                                <i class="fa fa-folder-open mr-2"></i> Select File
                            </button>
                        </div>
                    </label>
                </div>
                
                <div id="file-info" class="mb-6 hidden">
                    <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                        <div class="flex items-center">
                            <i id="file-icon" class="fa fa-file-text-o text-2xl text-primary mr-3"></i>
                            <div>
                                <p id="file-name" class="font-medium text-gray-800"></p>
                                <p id="file-size" class="text-sm text-gray-500"></p>
                            </div>
                        </div>
                        <button id="remove-file" class="text-red-500 hover:text-red-600">
                            <i class="fa fa-times"></i>
                        </button>
                    </div>
                </div>
                
                <div class="flex flex-col md:flex-row gap-4 mb-6">
                    <div class="flex-1">
                        <label for="file-source-language" class="block text-sm font-medium text-gray-700 mb-1">Source Language</label>
                        <select id="file-source-language" class="w-full bg-white border border-gray-300 text-gray-700 py-2 px-3 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary">
                            <option value="en">English</option>
                            <option value="zh">Chinese</option>
                            <option value="auto">Auto-detect</option>
                        </select>
                    </div>
                    <div class="flex-1">
                        <label for="file-target-language" class="block text-sm font-medium text-gray-700 mb-1">Target Language</label>
                        <select id="file-target-language" class="w-full bg-white border border-gray-300 text-gray-700 py-2 px-3 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary">
                            <option value="zh">Chinese</option>
                            <option value="en">English</option>
                        </select>
                    </div>
                </div>
                
                <div class="flex justify-center">
                    <button id="translate-file-button" class="bg-primary hover:bg-secondary text-white font-medium py-3 px-8 rounded-lg shadow hover:shadow-md transition-all disabled:opacity-50 disabled:cursor-not-allowed" disabled>
                        <i class="fa fa-file-text-o mr-2"></i> Translate Document
                    </button>
                </div>
            </div>
            
            <!-- File Translation Result -->
            <div id="file-translation-result" class="border-t border-gray-200 p-6 hidden">
                <h3 class="text-lg font-bold text-gray-800 mb-4">Translation Result</h3>
                
                <div class="bg-gray-50 p-4 rounded-lg mb-4">
                    <div class="flex items-center justify-between mb-2">
                        <div class="flex items-center">
                            <i class="fa fa-file-text-o text-xl text-primary mr-2"></i>
                            <span id="translated-file-name" class="font-medium text-gray-800"></span>
                        </div>
                        <div class="text-sm text-gray-500">
                            <span id="translation-time"></span>
                        </div>
                    </div>
                    <div id="file-translation-preview" class="max-h-60 overflow-auto custom-scrollbar p-4 bg-white rounded border border-gray-200">
                        <!-- Preview of translated content -->
                    </div>
                </div>
                
                <div class="flex justify-center">
                    <button id="download-translated-file" class="bg-primary hover:bg-secondary text-white font-medium py-2 px-6 rounded-lg shadow hover:shadow-md transition-all">
                        <i class="fa fa-download mr-2"></i> Download Translated File
                    </button>
                </div>
            </div>
        </div>
    </section>

    <!-- Help Section -->
    <section id="help-section" class="mb-12 hidden">
        <div class="bg-white rounded-xl shadow-custom-lg overflow-hidden">
            <div class="p-6">
                <h2 class="text-xl font-bold text-gray-800 mb-6">Help & Documentation</h2>
                
                <div class="mb-8">
                    <h3 class="text-lg font-semibold text-gray-800 mb-3">Text Translation</h3>
                    <p class="text-gray-600 mb-4">The text translation feature allows you to translate any text from English to Chinese or vice versa. Simply enter or paste your text in the source language box, select the source and target languages, and click the "Translate" button.</p>
                    <div class="bg-blue-50 border-l-4 border-blue-500 p-4 rounded">
                        <p class="text-blue-700"><strong>Tip:</strong> You can also select any text in the source box to see an instant translation popup.</p>
                    </div>
                </div>
                
                <div class="mb-8">
                    <h3 class="text-lg font-semibold text-gray-800 mb-3">Document Translation</h3>
                    <p class="text-gray-600 mb-4">The document translation feature supports various file formats including TXT, PDF, DOC, and DOCX. Upload your file, select the source and target languages, and click "Translate Document". The translated document will be available for download while preserving the original formatting as much as possible.</p>
                    <div class="bg-yellow-50 border-l-4 border-yellow-500 p-4 rounded">
                        <p class="text-yellow-700"><strong>Note:</strong> Large files may take longer to process. The maximum file size is 10MB.</p>
                    </div>
                </div>
                
                <div class="mb-8">
                    <h3 class="text-lg font-semibold text-gray-800 mb-3">Translation Engines</h3>
                    <p class="text-gray-600 mb-4">Our service supports multiple translation engines:</p>
                    <ul class="list-disc pl-6 space-y-2 text-gray-600">
                        <li><strong>Google Translate</strong> - Offers a good balance between accuracy and speed, with support for many languages.</li>
                        <li><strong>DeepL</strong> - Known for its high-quality translations, especially for European languages.</li>
                        <li><strong>Baidu Translate</strong> - Optimized for Chinese language pairs with excellent performance.</li>
                    </ul>
                    <p class="text-gray-600 mt-4">You can select your preferred translation engine from the dropdown menu in the top navigation bar.</p>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold text-gray-800 mb-3">FAQ</h3>
                    <div class="space-y-4">
                        <div>
                            <h4 class="font-medium text-gray-800">Is my data secure?</h4>
                            <p class="text-gray-600">Yes, we take data privacy seriously. Your texts and documents are processed securely, and we do not store your translation content after the translation is complete.</p>
                        </div>
                        <div>
                            <h4 class="font-medium text-gray-800">Are there any usage limits?</h4>
                            <p class="text-gray-600">For free users, there is a daily limit of 5,000 characters for text translation and 2 documents per day for document translation. Consider upgrading to our premium plan for higher limits.</p>
                        </div>
                        <div>
                            <h4 class="font-medium text-gray-800">How accurate are the translations?</h4>
                            <p class="text-gray-600">While our translation engines provide high-quality results, machine translation is not perfect. For critical or professional documents, we recommend having the translation reviewed by a human translator.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
    </main>

    <!-- Translation Popup -->
    <div id="translation-popup" class="translation-popup">
        <div class="flex justify-between items-center mb-2">
            <h4 class="font-medium text-gray-800">Translation</h4>
            <button id="close-popup" class="text-gray-400 hover:text-gray-600">
                <i class="fa fa-times"></i>
            </button>
        </div>
        <div id="popup-content" class="text-gray-700"></div>
    </div>

    <!-- Footer -->
    <footer class="bg-gray-800 text-white py-8">
        <div class="container mx-auto px-4">
            <div class="flex flex-col md:flex-row justify-between items-center">
                <div class="mb-4 md:mb-0">
                    <div class="flex items-center space-x-2">
                        <img src="https://p3-flow-imagex-sign.byteimg.com/tos-cn-i-a9rns2rl98/rc/pc/super_tool/239a7aec67ee4d14ba3be3186f1a3abb~tplv-a9rns2rl98-image.image?rcl=20251203230602FF5F18236405B6B744D7&rk3s=8e244e95&rrcfp=f06b921b&x-expires=1767366402&x-signature=Go1NWwYa9%2F4YomWFBn3gPRE8x4M%3D" alt="TransLingo Logo" class="h-8 w-auto invert">
                        <h2 class="text-lg font-bold">TransLingo</h2>
                    </div>
                    <p class="text-gray-400 text-sm mt-2">English-Chinese Translation Tool</p>
                </div>
                
                <div class="flex space-x-8">
                    <div>
                        <h3 class="text-sm font-semibold text-gray-300 uppercase tracking-wider mb-3">Features</h3>
                        <ul class="space-y-2">
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors" id="footer-text">Text Translation</a></li>
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors" id="footer-file">File Translation</a></li>
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors">API</a></li>
                        </ul>
                    </div>
                    
                    <div>
                        <h3 class="text-sm font-semibold text-gray-300 uppercase tracking-wider mb-3">Resources</h3>
                        <ul class="space-y-2">
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors" id="footer-help">Help Center</a></li>
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors">Documentation</a></li>
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors">Blog</a></li>
                        </ul>
                    </div>
                    
                    <div>
                        <h3 class="text-sm font-semibold text-gray-300 uppercase tracking-wider mb-3">Company</h3>
                        <ul class="space-y-2">
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors">About</a></li>
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors">Privacy Policy</a></li>
                            <li><a href="#" class="text-gray-400 hover:text-white transition-colors">Terms of Service</a></li>
                        </ul>
                    </div>
                </div>
            </div>
            
            <div class="border-t border-gray-700 mt-8 pt-6 flex flex-col md:flex-row justify-between items-center">
                <p class="text-gray-400 text-sm">&copy; 2025 TransLingo. All rights reserved.</p>
                <div class="flex space-x-4 mt-4 md:mt-0">
                    <a href="#" class="text-gray-400 hover:text-white transition-colors">
                        <i class="fa fa-facebook"></i>
                    </a>
                    <a href="#" class="text-gray-400 hover:text-white transition-colors">
                        <i class="fa fa-twitter"></i>
                    </a>
                    <a href="#" class="text-gray-400 hover:text-white transition-colors">
                        <i class="fa fa-instagram"></i>
                    </a>
                    <a href="#" class="text-gray-400 hover:text-white transition-colors">
                        <i class="fa fa-github"></i>
                    </a>
                </div>
            </div>
        </div>
    </footer>

    <!-- JavaScript -->
    <script>
        // DOM Elements
        const mobileMenuButton = document.getElementById('mobile-menu-button');
        const mobileMenu = document.getElementById('mobile-menu');
        const navText = document.getElementById('nav-text');
        const navFile = document.getElementById('nav-file');
        const navHelp = document.getElementById('nav-help');
        const mobileNavText = document.getElementById('mobile-nav-text');
        const mobileNavFile = document.getElementById('mobile-nav-file');
        const mobileNavHelp = document.getElementById('mobile-nav-help');
        const footerText = document.getElementById('footer-text');
        const footerFile = document.getElementById('footer-file');
        const footerHelp = document.getElementById('footer-help');
        const startTextTranslation = document.getElementById('start-text-translation');
        const startFileTranslation = document.getElementById('start-file-translation');
        const textTranslationSection = document.getElementById('text-translation-section');
        const fileTranslationSection = document.getElementById('file-translation-section');
        const helpSection = document.getElementById('help-section');
        const sourceText = document.getElementById('source-text');
        const sourceTextPlaceholder = document.getElementById('source-text-placeholder');
        const translationResult = document.getElementById('translation-result');
        const translationPlaceholder = document.getElementById('translation-placeholder');
        const translationLoading = document.getElementById('translation-loading');
        const translateButton = document.getElementById('translate-button');
        const clearSource = document.getElementById('clear-source');
        const clearTarget = document.getElementById('clear-target');
        const copySource = document.getElementById('copy-source');
        const copyTarget = document.getElementById('copy-target');
        const pasteSource = document.getElementById('paste-source');
        const listenTarget = document.getElementById('listen-target');
        const swapLanguages = document.getElementById('swap-languages');
        const sourceLanguage = document.getElementById('source-language');
        const targetLanguage = document.getElementById('target-language');
        const characterCount = document.getElementById('character-count');
        const translationPopup = document.getElementById('translation-popup');
        const popupContent = document.getElementById('popup-content');
        const closePopup = document.getElementById('close-popup');
        const fileInput = document.getElementById('file-input');
        const fileInfo = document.getElementById('file-info');
        const fileName = document.getElementById('file-name');
        const fileSize = document.getElementById('file-size');
        const fileIcon = document.getElementById('file-icon');
        const removeFile = document.getElementById('remove-file');
        const translateFileButton = document.getElementById('translate-file-button');
        const fileTranslationResult = document.getElementById('file-translation-result');
        const translatedFileName = document.getElementById('translated-file-name');
        const translationTime = document.getElementById('translation-time');
        const fileTranslationPreview = document.getElementById('file-translation-preview');
        const downloadTranslatedFile = document.getElementById('download-translated-file');
        const fileSourceLanguage = document.getElementById('file-source-language');
        const fileTargetLanguage = document.getElementById('file-target-language');
        const translationEngine = document.getElementById('translation-engine');

        // Mobile menu toggle
        mobileMenuButton.addEventListener('click', () => {
            mobileMenu.classList.toggle('hidden');
        });

        // Navigation
        function showSection(section) {
            textTranslationSection.classList.add('hidden');
            fileTranslationSection.classList.add('hidden');
            helpSection.classList.add('hidden');
            
            navText.classList.remove('text-primary');
            navText.classList.add('text-gray-600');
            navFile.classList.remove('text-primary');
            navFile.classList.add('text-gray-600');
            navHelp.classList.remove('text-primary');
            navHelp.classList.add('text-gray-600');
            
            mobileNavText.classList.remove('text-primary');
            mobileNavText.classList.add('text-gray-600');
            mobileNavFile.classList.remove('text-primary');
            mobileNavFile.classList.add('text-gray-600');
            mobileNavHelp.classList.remove('text-primary');
            mobileNavHelp.classList.add('text-gray-600');
            
            if (section === 'text') {
                textTranslationSection.classList.remove('hidden');
                navText.classList.remove('text-gray-600');
                navText.classList.add('text-primary');
                mobileNavText.classList.remove('text-gray-600');
                mobileNavText.classList.add('text-primary');
            } else if (section === 'file') {
                fileTranslationSection.classList.remove('hidden');
                navFile.classList.remove('text-gray-600');
                navFile.classList.add('text-primary');
                mobileNavFile.classList.remove('text-gray-600');
                mobileNavFile.classList.add('text-primary');
            } else if (section === 'help') {
                helpSection.classList.remove('hidden');
                navHelp.classList.remove('text-gray-600');
                navHelp.classList.add('text-primary');
                mobileNavHelp.classList.remove('text-gray-600');
                mobileNavHelp.classList.add('text-primary');
            }
        }

        navText.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('text');
            mobileMenu.classList.add('hidden');
        });

        navFile.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('file');
            mobileMenu.classList.add('hidden');
        });

        navHelp.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('help');
            mobileMenu.classList.add('hidden');
        });

        mobileNavText.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('text');
            mobileMenu.classList.add('hidden');
        });

        mobileNavFile.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('file');
            mobileMenu.classList.add('hidden');
        });

        mobileNavHelp.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('help');
            mobileMenu.classList.add('hidden');
        });

        footerText.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('text');
        });

        footerFile.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('file');
        });

        footerHelp.addEventListener('click', (e) => {
            e.preventDefault();
            showSection('help');
        });

        startTextTranslation.addEventListener('click', () => {
            showSection('text');
            window.scrollTo({ top: textTranslationSection.offsetTop - 100, behavior: 'smooth' });
        });

        startFileTranslation.addEventListener('click', () => {
            showSection('file');
            window.scrollTo({ top: fileTranslationSection.offsetTop - 100, behavior: 'smooth' });
        });

        // Text Translation Functionality
        sourceText.addEventListener('input', () => {
            updateCharacterCount();
            togglePlaceholder();
        });

        function updateCharacterCount() {
            const count = sourceText.value.length;
            characterCount.textContent = count;
        }

        function togglePlaceholder() {
            if (sourceText.value.trim() !== '') {
                sourceTextPlaceholder.classList.add('hidden');
            } else {
                sourceTextPlaceholder.classList.remove('hidden');
            }
        }

        // Translation API Simulation
        function translateText(text, sourceLang, targetLang, engine) {
            // Show loading state
            translationPlaceholder.classList.add('hidden');
            translationResult.classList.add('hidden');
            translationLoading.classList.remove('hidden');
            
            // Simulate API call delay
            setTimeout(() => {
                let translatedText = '';
                
                // Mock translations based on engine
                if (engine === 'google') {
                    if (targetLang === 'zh') {
                        translatedText = mockGoogleTranslationToChinese(text);
                    } else {
                        translatedText = mockGoogleTranslationToEnglish(text);
                    }
                } else if (engine === 'deepl') {
                    if (targetLang === 'zh') {
                        translatedText = mockDeepLTranslationToChinese(text);
                    } else {
                        translatedText = mockDeepLTranslationToEnglish(text);
                    }
                } else if (engine === 'baidu') {
                    if (targetLang === 'zh') {
                        translatedText = mockBaiduTranslationToChinese(text);
                    } else {
                        translatedText = mockBaiduTranslationToEnglish(text);
                    }
                }
                
                // Hide loading and show result
                translationLoading.classList.add('hidden');
                translationResult.classList.remove('hidden');
                translationResult.innerHTML = `<p>${translatedText}</p>`;
                
                // Add copy button functionality
                copyTarget.disabled = false;
            }, 1000);
        }

        // Mock translation functions
        function mockGoogleTranslationToChinese(text) {
            // This is a very simple mock - in a real app, this would be an API call
            const translations = {
                'hello': '你好',
                'world': '世界',
                'hello world': '你好，世界',
                'how are you': '你好吗',
                'i am fine': '我很好',
                'thank you': '谢谢',
                'welcome': '欢迎',
                'good morning': '早上好',
                'good afternoon': '下午好',
                'good evening': '晚上好',
                'goodbye': '再见',
                'see you later': '待会儿见',
                'where are you': '你在哪里',
                'i am here': '我在这里',
                'what is your name': '你叫什么名字',
                'my name is': '我的名字是',
                'nice to meet you': '很高兴认识你',
                'how old are you': '你多大了',
                'i am years old': '我岁了',
                'where are you from': '你来自哪里',
                'i am from': '我来自',
                'do you speak english': '你会说英语吗',
                'yes i do': '是的，我会',
                'no i dont': '不，我不会',
                'i love you': '我爱你',
                'i miss you': '我想你',
                'happy birthday': '生日快乐',
                'congratulations': '恭喜',
                'good luck': '祝你好运',
                'have a nice day': '祝你有美好的一天',
                'excuse me': '对不起',
                'sorry': '抱歉',
                'please': '请',
                'thank you very much': '非常感谢',
                'you are welcome': '不客气',
                'how much is this': '这个多少钱',
                'too expensive': '太贵了',
                'can you help me': '你能帮我吗',
                'i need help': '我需要帮助',
                'where is the bathroom': '洗手间在哪里',
                'i am lost': '我迷路了',
                'i dont understand': '我不明白',
                'please speak slowly': '请说慢一点',
                'please repeat': '请重复',
                'cheers': '干杯',
                'happy new year': '新年快乐',
                'merry christmas': '圣诞快乐',
                'happy easter': '复活节快乐',
                'happy thanksgiving': '感恩节快乐',
                'valentines day': '情人节快乐',
                'halloween': '万圣节快乐',
                'april fools': '愚人节快乐',
                'i am hungry': '我饿了',
                'i am thirsty': '我渴了',
                'i am tired': '我累了',
                'i am sick': '我生病了',
                'i need to rest': '我需要休息',
                'i have a headache': '我头痛',
                'i have a stomachache': '我胃痛',
                'i have a fever': '我发烧了',
                'call the doctor': '叫医生',
                'i need medicine': '我需要药',
                'i am allergic to': '我对过敏',
                'do you have': '你有吗',
                'i want to buy': '我想买',
                'i need to sell': '我需要卖',
                'i am looking for': '我在找',
                'where can i find': '我在哪里可以找到',
                'this is beautiful': '这很漂亮',
                'i like it': '我喜欢它',
                'i dont like it': '我不喜欢它',
                'this is amazing': '这太棒了',
                'this is terrible': '这太糟糕了',
                'i agree': '我同意',
                'i disagree': '我不同意',
                'maybe': '也许',
                'probably': '可能',
                'definitely': '肯定',
                'absolutely': '绝对',
                'maybe not': '也许不',
                'probably not': '可能不',
                'definitely not': '肯定不',
                'absolutely not': '绝对不',
                'i think so': '我想是这样',
                'i dont think so': '我不这么认为',
                'i hope so': '我希望如此',
                'i hope not': '我希望不是',
                'i am sure': '我确定',
                'i am not sure': '我不确定',
                'i know': '我知道',
                'i dont know': '我不知道',
                'i understand': '我明白',
                'i dont understand': '我不明白',
                'i remember': '我记得',
                'i forget': '我忘记了',
                'i believe': '我相信',
                'i dont believe': '我不相信',
                'i trust you': '我信任你',
                'i dont trust you': '我不信任你',
                'i am happy': '我很高兴',
                'i am sad': '我很伤心',
                'i am angry': '我很生气',
                'i am scared': '我很害怕',
                'i am excited': '我很兴奋',
                'i am nervous': '我很紧张',
                'i am relaxed': '我很放松',
                'i am bored': '我很无聊',
                'i am confused': '我很困惑',
                'i am interested': '我很感兴趣',
                'i am not interested': '我不感兴趣',
                'i am surprised': '我很惊讶',
                'i am disappointed': '我很失望',
                'i am proud': '我很自豪',
                'i am ashamed': '我很羞愧',
                'i am grateful': '我很感激',
                'i am thankful': '我很感谢',
                'i am sorry': '我很抱歉',
                'i forgive you': '我原谅你',
                'i love you': '我爱你',
                'i hate you': '我恨你',
                'i miss you': '我想你',
                'i need you': '我需要你',
                'i want you': '我想要你',
                'i like you': '我喜欢你',
                'i dont like you': '我不喜欢你',
                'you are beautiful': '你很漂亮',
                'you are handsome': '你很帅',
                'you are smart': '你很聪明',
                'you are stupid': '你很愚蠢',
                'you are kind': '你很善良',
                'you are mean': '你很刻薄',
                'you are funny': '你很有趣',
                'you are boring': '你很无聊',
                'you are nice': '你很好',
                'you are bad': '你很坏',
                'you are welcome': '不客气',
                'thank you': '谢谢',
                'please': '请',
                'sorry': '对不起',
                'excuse me': '打扰一下',
                'bless you': '保佑你',
                'congratulations': '恭喜',
                'good luck': '祝你好运',
                'have fun': '玩得开心',
                'enjoy yourself': '尽情享受',
                'take care': '保重',
                'be careful': '小心',
                'dont worry': '别担心',
                'calm down': '冷静下来',
                'relax': '放松',
                'hurry up': '快点',
                'slow down': '慢一点',
                'wait': '等等',
                'stop': '停下',
                'go': '走',
                'come': '来',
                'stay': '留下',
                'leave': '离开',
                'help': '帮助',
                'save': '保存',
                'delete': '删除',
                'copy': '复制',
                'paste': '粘贴',
                'cut': '剪切',
                'undo': '撤销',
                'redo': '重做',
                'print': '打印',
                'download': '下载',
                'upload': '上传',
                'open': '打开',
                'close': '关闭',
                'save': '保存',
                'exit': '退出',
                'log in': '登录',
                'log out': '登出',
                'sign up': '注册',
                'sign in': '登录',
                'forgot password': '忘记密码',
                'change password': '修改密码',
                'profile': '个人资料',
                'settings': '设置',
                'preferences': '偏好设置',
                'language': '语言',
                'theme': '主题',
                'dark mode': '深色模式',
                'light mode': '浅色模式',
                'notifications': '通知',
                'messages': '消息',
                'inbox': '收件箱',
                'outbox': '发件箱',
                'sent': '已发送',
                'draft': '草稿',
                'trash': '垃圾箱',
                'spam': '垃圾邮件',
                'archive': '归档',
                'search': '搜索',
                'filter': '筛选',
                'sort': '排序',
                'refresh': '刷新',
                'reload': '重新加载',
                'home': '首页',
                'dashboard': '仪表盘',
                'profile': '个人资料',
                'settings': '设置',
                'help': '帮助',
                'support': '支持',
                'contact': '联系我们',
                'about': '关于我们',
                'privacy': '隐私政策',
                'terms': '服务条款',
                'logout': '登出',
                'login': '登录',
                'register': '注册',
                'submit': '提交',
                'cancel': '取消',
                'confirm': '确认',
                'agree': '同意',
                'disagree': '不同意',
                'accept': '接受',
                'decline': '拒绝',
                'yes': '是',
                'no': '否',
                'maybe': '也许',
                'ok': '好的',
                'fine': '好的',
                'great': '太好了',
                'wonderful': '太棒了',
                'excellent': '优秀',
                'amazing': '令人惊叹',
                'terrible': '糟糕',
                'awful': '可怕',
                'horrible': '恐怖',
                'fantastic': '极好的',
                'superb': '卓越的',
                'magnificent': '壮丽的',
                'marvelous': '奇妙的',
                'outstanding': '杰出的',
                'exceptional': '例外的',
                'extraordinary': '非凡的',
                'remarkable': '显著的',
                'impressive': '令人印象深刻的',
                'wonderful': '美妙的',
                'lovely': '可爱的',
                'nice': '好的',
                'good': '好的',
                'bad': '坏的',
                'poor': '差的',
                'average': '一般的',
                'fair': '公平的',
                'excellent': '优秀的',
                'perfect': '完美的',
                'imperfect': '不完美的',
                'complete': '完整的',
                'incomplete': '不完整的',
                'full': '满的',
                'empty': '空的',
                'big': '大的',
                'small': '小的',
                'large': '大的',
                'tiny': '微小的',
                'huge': '巨大的',
                'enormous': '庞大的',
                'gigantic': '巨大的',
                'massive': '大规模的',
                'minuscule': '极小的',
                'tall': '高的',
                'short': '矮的',
                'long': '长的',
                'wide': '宽的',
                'narrow': '窄的',
                'deep': '深的',
                'shallow': '浅的',
                'thick': '厚的',
                'thin': '薄的',
                'heavy': '重的',
                'light': '轻的',
                'hard': '硬的',
                'soft': '软的',
                'rough': '粗糙的',
                'smooth': '光滑的',
                'sharp': '锋利的',
                'blunt': '钝的',
                'hot': '热的',
                'cold': '冷的',
                'warm': '温暖的',
                'cool': '凉爽的',
                'wet': '湿的',
                'dry': '干的',
                'clean': '干净的',
                'dirty': '脏的',
                'tidy': '整洁的',
                'messy': '凌乱的',
                'neat': '整洁的',
                'disorganized': '混乱的',
                'organized': '有组织的',
                'new': '新的',
                'old': '旧的',
                'young': '年轻的',
                'old': '老的',
                'fresh': '新鲜的',
                'stale': '陈的',
                'good': '好的',
                'bad': '坏的',
                'nice': '好的',
                'mean': '刻薄的',
                'kind': '善良的',
                'cruel': '残忍的',
                'friendly': '友好的',
                'unfriendly': '不友好的',
                'polite': '有礼貌的',
                'rude': '粗鲁的',
                'honest': '诚实的',
                'dishonest': '不诚实的',
                'truthful': '真实的',
                'lying': '说谎的',
                'loyal': '忠诚的',
                'disloyal': '不忠诚的',
                'faithful': '忠实的',
                'unfaithful': '不忠实的',
                'trustworthy': '值得信赖的',
                'untrustworthy': '不值得信赖的',
                'reliable': '可靠的',
                'unreliable': '不可靠的',
                'dependable': '可依赖的',
                'undependable': '不可依赖的',
                'responsible': '负责任的',
                'irresponsible': '不负责任的',
                'careful': '小心的',
                'careless': '粗心的',
                'cautious': '谨慎的',
                'reckless': '鲁莽的',
                'brave': '勇敢的',
                'cowardly': '胆小的',
                'bold': '大胆的',
                'timid': '胆小的',
                'confident': '自信的',
                'insecure': '不安全的',
                'proud': '自豪的',
                'humble': '谦虚的',
                'arrogant': '傲慢的',
                'modest': '谦虚的',
                'conceited': '自负的',
                'generous': '慷慨的',
                'stingy': '吝啬的',
                'kind': '善良的',
                'selfish': '自私的',
                'thoughtful': '体贴的',
                'thoughtless': '轻率的',
                'considerate': '考虑周到的',
                'inconsiderate': '不考虑他人的',
                'helpful': '有帮助的',
                'unhelpful': '无帮助的',
                'cooperative': '合作的',
                'uncooperative': '不合作的',
                'friendly': '友好的',
                'hostile': '敌对的',
                'peaceful': '和平的',
                'violent': '暴力的',
                'calm': '平静的',
                'agitated': '激动的',
                'relaxed': '放松的',
                'stressed': '紧张的',
                'happy': '快乐的',
                'sad': '悲伤的',
                'joyful': '欢乐的',
                'miserable': '痛苦的',
                'excited': '兴奋的',
                'bored': '无聊的',
                'enthusiastic': '热情的',
                'apathetic': '冷漠的',
                'passionate': '热情的',
                'indifferent': '漠不关心的',
                'lively': '活泼的',
                'dull': ' dull的',
                'energetic': '精力充沛的',
                'tired': '疲倦的',
                'active': '活跃的',
                'inactive': '不活跃的',
                'alert': '警觉的',
                'sleepy': '困倦的',
                'wakeful': '醒着的',
                'asleep': '睡着的',
                'aware': '意识到的',
                'unaware': '未意识到的',
                'conscious': '有意识的',
                'unconscious': '无意识的',
                'smart': '聪明的',
                'stupid': '愚蠢的',
                'intelligent': '聪明的',
                'ignorant': '无知的',
                'clever': '聪明的',
                'foolish': '愚蠢的',
                'wise': '明智的',
                'silly': '傻的',
                'brilliant': '杰出的',
                'dumb': '哑的',
                'genius': '天才的',
                'idiot': '白痴的',
                'creative': '创造性的',
                'unimaginative': '缺乏想象力的',
                'original': '原创的',
                'derivative': '衍生的',
                'innovative': '创新的',
                'conventional': '传统的',
                'unique': '独特的',
                'common': '常见的',
                'special': '特殊的',
                'ordinary': '普通的',
                'rare': '稀有的',
                'frequent': '频繁的',
                'scarce': '稀少的',
                'plentiful': '丰富的',
                'abundant': '丰富的',
                'limited': '有限的',
                'unlimited': '无限的',
                'sufficient': '足够的',
                'insufficient': '不足的',
                'adequate': '足够的',
                'inadequate': '不足的',
                'excess': '过量的',
                'deficient': '不足的',
                'more': '更多的',
                'less': '更少的',
                'most': '最多的',
                'least': '最少的',
                'many': '许多的',
                'few': '很少的',
                'much': '许多的',
                'little': '很少的',
                'some': '一些的',
                'none': '没有的',
                'all': '所有的',
                'whole': '整个的',
                'partial': '部分的',
                'complete': '完整的',
                'incomplete': '不完整的',
                'total': '总的',
                'partial': '部分的',
                'every': '每个的',
                'each': '每个的',
                'any': '任何的',
                'either': '任一的',
                'neither': '两者都不的',
                'both': '两者都的',
                'several': '几个的',
                'various': '各种各样的',
                'different': '不同的',
                'same': '相同的',
                'similar': '相似的',
                'dissimilar': '不相似的',
                'alike': '相似的',
                'unlike': '不相似的',
                'identical': '相同的',
                'distinct': '不同的',
                'separate': '分开的',
                'connected': '连接的',
                'joined': '连接的',
                'detached': '分离的',
                'attached': '附加的',
                'free': '自由的',
                'restricted': '受限制的',
                'open': '开放的',
                'closed': '关闭的',
                'accessible': '可访问的',
                'inaccessible': '不可访问的',
                'available': '可用的',
                'unavailable': '不可用的',
                'ready': '准备好的',
                'unready': '未准备好的',
                'willing': '愿意的',
                'unwilling': '不愿意的',
                'eager': '渴望的',
                'reluctant': '不情愿的',
                'anxious': '焦虑的',
                'calm': '平静的',
                'worried': '担心的',
                'relaxed': '放松的',
                'nervous': '紧张的',
                'confident': '自信的',
                'afraid': '害怕的',
                'brave': '勇敢的',
                'fearful': '害怕的',
                'bold': '大胆的',
                'timid': '胆小的',
                'shy': '害羞的',
                'outgoing': '外向的',
                'introverted': '内向的',
                'extroverted': '外向的',
                'sociable': '社交的',
                'unsociable': '不社交的',
                'friendly': '友好的',
                'unfriendly': '不友好的',
                'kind': '善良的',
                'unkind': '不善良的',
                'nice': '好的',
                'mean': '刻薄的',
                'pleasant': '愉快的',
                'unpleasant': '不愉快的',
                'happy': '快乐的',
                'sad': '悲伤的',
                'glad': '高兴的',
                'sorry': '抱歉的',
                'delighted': '高兴的',
                'disappointed': '失望的',
                'pleased': '高兴的',
                'displeased': '不高兴的',
                'satisfied': '满意的',
                'unsatisfied': '不满意的',
                'content': '满足的',
                'discontent': '不满的',
                'grateful': '感激的',
                'ungrateful': '忘恩负义的',
                'thankful': '感谢的',
                'unthankful': '不感谢的',
                'lucky': '幸运的',
                'unlucky': '不幸的',
                'fortunate': '幸运的',
                'unfortunate': '不幸的',
                'successful': '成功的',
                'unsuccessful': '不成功的',
                'prosperous': '繁荣的',
                'poor': '贫穷的',
                'rich': '富有的',
                'wealthy': '富有的',
                'needy': '贫困的',
                'generous': '慷慨的',
                'stingy': '吝啬的',
                'liberal': '自由主义的',
                'conservative': '保守的',
                'moderate': '温和的',
                'extreme': '极端的',
                'radical': '激进的',
                'reactionary': '反动的',
                'progressive': '进步的',
                'backward': '落后的',
                'modern': '现代的',
                'traditional': '传统的',
                'old-fashioned': '过时的',
                'fashionable': '时尚的',
                'outdated': '过时的',
                'current': '当前的',
                'obsolete': '过时的',
                'new': '新的',
                'old': '旧的',
                'young': '年轻的',
                'old': '老的',
                'fresh': '新鲜的',
                'stale': '陈的',
                'original': '原创的',
                'copy': '复制的',
                'genuine': '真正的',
                'fake': '假的',
                'real': '真实的',
                'imaginary': '想象的',
                'authentic': '真实的',
                'counterfeit': '伪造的',
                'natural': '自然的',
                'artificial': '人工的',
                'organic': '有机的',
                'synthetic': '合成的',
                'pure': '纯净的',
                'impure': '不纯的',
                'clean': '干净的',
                'dirty': '脏的',
                'clear': '清晰的',
                'cloudy': '多云的',
                'transparent': '透明的',
                'opaque': '不透明的',
                'bright': '明亮的',
                'dark': '黑暗的',
                'light': '轻的',
                'heavy': '重的',
                'soft': '软的',
                'hard': '硬的',
                'smooth': '光滑的',
                'rough': '粗糙的',
                'wet': '湿的',
                'dry': '干的',
                'hot': '热的',
                'cold': '冷的',
                'warm': '温暖的',
                'cool': '凉爽的',
                'sharp': '锋利的',
                'blunt': '钝的',
                'pointed': '尖的',
                'rounded': '圆的',
                'flat': '平的',
                'curved': '弯曲的',
                'straight': '直的',
                'crooked': '弯曲的',
                'narrow': '窄的',
                'wide': '宽的',
                'thick': '厚的',
                'thin': '薄的',
                'short': '短的',
                'long': '长的',
                'tall': '高的',
                'low': '低的',
                'deep': '深的',
                'shallow': '浅的',
                'small': '小的',
                'large': '大的',
                'tiny': '微小的',
                'huge': '巨大的',
                'enormous': '庞大的',
                'gigantic': '巨大的',
                'massive': '大规模的',
                'minuscule': '极小的',
                'average': '平均的',
                'normal': '正常的',
                'standard': '标准的',
                'regular': '常规的',
                'common': '常见的',
                'ordinary': '普通的',
                'usual': '通常的',
                'typical': '典型的',
                'unusual': '不寻常的',
                'rare': '稀有的',
                'strange': '奇怪的',
                'odd': '奇怪的',
                'peculiar': '特殊的',
                'unique': '独特的',
                'different': '不同的',
                'weird': '怪异的',
                'bizarre': '奇异的',
                'abnormal': '异常的',
                'irregular': '不规则的',
                'unconventional': '非常规的',
                'unorthodox': '非正统的',
                'alternative': '替代的',
                'traditional': '传统的',
                'conventional': '传统的',
                'orthodox': '正统的',
                'formal': '正式的',
                'informal': '非正式的',
                'casual': '随意的',
                'serious': '严肃的',
                'playful': '好玩的',
                'professional': '专业的',
                'amateur': '业余的',
                'expert': '专家的',
                'novice': '新手的',
                'skilled': '熟练的',
                'unskilled': '不熟练的',
                'experienced': '有经验的',
                'inexperienced': '缺乏经验的',
                'qualified': '合格的',
                'unqualified': '不合格的',
                'competent': '有能力的',
                'incompetent': '无能力的',
                'efficient': '高效的',
                'inefficient': '低效的',
                'effective': '有效的',
                'ineffective': '无效的',
                'productive': '多产的',
                'unproductive': '不生产的',
                'useful': '有用的',
                'useless': '无用的',
                'valuable': '有价值的',
                'worthless': '无价值的',
                'beneficial': '有益的',
                'harmful': '有害的',
                'helpful': '有帮助的',
                'harmful': '有害的',
                'positive': '积极的',
                'negative': '消极的',
                'good': '好的',
                'bad': '坏的',
                'right': '正确的',
                'wrong': '错误的',
                'true': '真实的',
                'false': '假的',
                'correct': '正确的',
                'incorrect': '不正确的',
                'accurate': '准确的',
                'inaccurate': '不准确的',
                'precise': '精确的',
                'imprecise': '不精确的',
                'exact': '确切的',
                'inexact': '不确切的',
                'specific': '具体的',
                'general': '一般的',
                'detailed': '详细的',
                'vague': '模糊的',
                'clear': '清晰的',
                'unclear': '不清楚的',
                'obvious': '明显的',
                'hidden': '隐藏的',
                'apparent': '明显的',
                'subtle': '微妙的',
                'evident': '明显的',
                'secret': '秘密的',
                'public': '公共的',
                'private': '私人的',
                'confidential': '机密的',
                'open': '开放的',
                'closed': '关闭的',
                'known': '已知的',
                'unknown': '未知的',
                'familiar': '熟悉的',
                'unfamiliar': '不熟悉的',
                'recognizable': '可识别的',
                'unrecognizable': '不可识别的',
                'similar': '相似的',
                'different': '不同的',
                'same': '相同的',
                'alike': '相似的',
                'unlike': '不相似的',
                'identical': '相同的',
                'distinct': '不同的',
                'separate': '分开的',
                'connected': '连接的',
                'joined': '连接的',
                'detached': '分离的',
                'attached': '附加的',
                'free': '自由的',
                'restricted': '受限制的',
                'open': '开放的',
                'closed': '关闭的',
                'accessible': '可访问的',
                'inaccessible': '不可访问的',
                'available': '可用的',
                'unavailable': '不可用的',
                'ready': '准备好的',
                'unready': '未准备好的',
                'willing': '愿意的',
                'unwilling': '不愿意的',
                'eager': '渴望的',
                'reluctant': '不情愿的',
                'anxious': '焦虑的',
                'calm': '平静的',
                'worried': '担心的',
                'relaxed': '放松的',
                'nervous': '紧张的',
                'confident': '自信的',
                'afraid': '害怕的',
                'brave': '勇敢的',
                'fearful': '害怕的',
                'bold': '大胆的',
                'timid': '胆小的',
                'shy': '害羞的',
                'outgoing': '外向的',
                'introverted': '内向的',
                'extroverted': '外向的',
                'sociable': '社交的',
                'unsociable': '不社交的',
                'friendly': '友好的',
                'unfriendly': '不友好的',
                'kind': '善良的',
                'unkind': '不善良的',
                'nice': '好的',
                'mean': '刻薄的',
                'pleasant': '愉快的',
                'unpleasant': '不愉快的',
                'happy': '快乐的',
                'sad': '悲伤的',
                'glad': '高兴的',
                'sorry': '抱歉的',
                'delighted': '高兴的',
                'disappointed': '失望的',
                'pleased': '高兴的',
                'displeased': '不高兴的',
                'satisfied': '满意的',
                'unsatisfied': '不满意的',
                'content': '满足的',
                'discontent': '不满的',
                'grateful': '感激的',
                'ungrateful': '忘恩负义的',
                'thankful': '感谢的',
                'unthankful': '不感谢的',
                'lucky': '幸运的',
                'unlucky': '不幸的',
                'fortunate': '幸运的',
                'unfortunate': '不幸的',
                'successful': '成功的',
                'unsuccessful': '不成功的',
                'prosperous': '繁荣的',
                'poor': '贫穷的',
                'rich': '富有的',
                'wealthy': '富有的',
                'needy': '贫困的',
                'generous': '慷慨的',
                'stingy': '吝啬的',
                'liberal': '自由主义的',
                'conservative': '保守的',
                'moderate': '温和的',
                'extreme': '极端的',
                'radical': '激进的',
                'reactionary': '反动的',
                'progressive': '进步的',
                'backward': '落后的',
                'modern': '现代的',
                'traditional': '传统的',
                'old-fashioned': '过时的',
                'fashionable': '时尚的',
                'outdated': '过时的',
                'current': '当前的',
                'obsolete': '过时的'
            };
            
            // Check if exact translation exists
            if (translations[text.toLowerCase()]) {
                return translations[text.toLowerCase()];
            }
            
            // Simple mock translation for sentences
            if (text.includes('hello')) {
                return text.replace(/hello/gi, '你好');
            }
            if (text.includes('world')) {
                return text.replace(/world/gi, '世界');
            }
            if (text.includes('thank you')) {
                return text.replace(/thank you/gi, '谢谢');
            }
            if (text.includes('good morning')) {
                return text.replace(/good morning/gi, '早上好');
            }
            if (text.includes('good afternoon')) {
                return text.replace(/good afternoon/gi, '下午好');
            }
            if (text.includes('good evening')) {
                return text.replace(/good evening/gi, '晚上好');
            }
            if (text.includes('goodbye')) {
                return text.replace(/goodbye/gi, '再见');
            }
            
            // Default fallback
            return `[Google 翻译] ${text} 的中文翻译结果。这是一个模拟翻译，实际应用中会调用真实的翻译API。`;
        }

        function mockGoogleTranslationToEnglish(text) {
            // Simple mock translations for common Chinese phrases
            const translations = {
                '你好': 'Hello',
                '世界': 'World',
                '你好，世界': 'Hello, World',
                '你好吗': 'How are you',
                '我很好': 'I am fine',
                '谢谢': 'Thank you',
                '欢迎': 'Welcome',
                '早上好': 'Good morning',
                '下午好': 'Good afternoon',
                '晚上好': 'Good evening',
                '再见': 'Goodbye',
                '待会儿见': 'See you later',
                '你在哪里': 'Where are you',
                '我在这里': 'I am here',
                '你叫什么名字': 'What is your name',
                '我的名字是': 'My name is',
                '很高兴认识你': 'Nice to meet you',
                '你多大了': 'How old are you',
                '我岁了': 'I am years old',
                '你来自哪里': 'Where are you from',
                '我来自': 'I am from',
                '你会说英语吗': 'Do you speak English',
                '是的，我会': 'Yes, I do',
                '不，我不会': 'No, I don\'t',
                '我爱你': 'I love you',
                '我想你': 'I miss you',
                '生日快乐': 'Happy birthday',
                '恭喜': 'Congratulations',
                '祝你好运': 'Good luck',
                '祝你有美好的一天': 'Have a nice day',
                '对不起': 'Excuse me',
                '抱歉': 'Sorry',
                '请': 'Please',
                '非常感谢': 'Thank you very much',
                '不客气': 'You are welcome',
                '这个多少钱': 'How much is this',
                '太贵了': 'Too expensive',
                '你能帮我吗': 'Can you help me',
                '我需要帮助': 'I need help',
                '洗手间在哪里': 'Where is the bathroom',
                '我迷路了': 'I am lost',
                '我不明白': 'I don\'t understand',
                '请说慢一点': 'Please speak slowly',
                '请重复': 'Please repeat',
                '干杯': 'Cheers',
                '新年快乐': 'Happy New Year',
                '圣诞快乐': 'Merry Christmas',
                '复活节快乐': 'Happy Easter',
                '感恩节快乐': 'Happy Thanksgiving',
                '情人节快乐': 'Happy Valentine\'s Day',
                '万圣节快乐': 'Happy Halloween',
                '愚人节快乐': 'April Fools',
                '我饿了': 'I am hungry',
                '我渴了': 'I am thirsty',
                '我累了': 'I am tired',
                '我生病了': 'I am sick',
                '我需要休息': 'I need to rest',
                '我头痛': 'I have a headache',
                '我胃痛': 'I have a stomachache',
                '我发烧了': 'I have a fever',
                '叫医生': 'Call the doctor',
                '我需要药': 'I need medicine',
                '我对过敏': 'I am allergic to',
                '你有吗': 'Do you have',
                '我想买': 'I want to buy',
                '我需要卖': 'I need to sell',
                '我在找': 'I am looking for',
                '我在哪里可以找到': 'Where can I find',
                '这很漂亮': 'This is beautiful',
                '我喜欢它': 'I like it',
                '我不喜欢它': 'I don\'t like it',
                '这太棒了': 'This is amazing',
                '这太糟糕了': 'This is terrible',
                '我同意': 'I agree',
                '我不同意': 'I disagree',
                '也许': 'Maybe',
                '可能': 'Probably',
                '肯定': 'Definitely',
                '绝对': 'Absolutely',
                '也许不': 'Maybe not',
                '可能不': 'Probably not',
                '肯定不': 'Definitely not',
                '绝对不': 'Absolutely not',
                '我想是这样': 'I think so',
                '我不这么认为': 'I don\'t think so',
                '我希望如此': 'I hope so',
                '我希望不是': 'I hope not',
                '我确定': 'I am sure',
                '我不确定': 'I am not sure',
                '我知道': 'I know',
                '我不知道': 'I don\'t know',
                '我明白': 'I understand',
                '我不明白': 'I don\'t understand',
                '我记得': 'I remember',
                '我忘记了': 'I forget',
                '我相信': 'I believe',
                '我不相信': 'I don\'t believe',
                '我信任你': 'I trust you',
                '我不信任你': 'I don\'t trust you',
                '我很高兴': 'I am happy',
                '我很伤心': 'I am sad',
                '我很生气': 'I am angry',
                '我很害怕': 'I am scared',
                '我很兴奋': 'I am excited',
                '我很紧张': 'I am nervous',
                '我很放松': 'I am relaxed',
                '我很无聊': 'I am bored',
                '我很困惑': 'I am confused',
                '我很感兴趣': 'I am interested',
                '我不感兴趣': 'I am not interested',
                '我很惊讶': 'I am surprised',
                '我很失望': 'I am disappointed',
                '我很自豪': 'I am proud',
                '我很羞愧': 'I am ashamed',
                '我很感激': 'I am grateful',
                '我很感谢': 'I am thankful',
                '我很抱歉': 'I am sorry',
                '我原谅你': 'I forgive you',
                '我爱你': 'I love you',
                '我恨你': 'I hate you',
                '我想你': 'I miss you',
                '我需要你': 'I need you',
                '我想要你': 'I want you',
                '我喜欢你': 'I like you',
                '我不喜欢你': 'I don\'t like you',
                '你很漂亮': 'You are beautiful',
                '你很帅': 'You are handsome',
                '你很聪明': 'You are smart',
                '你很愚蠢': 'You are stupid',
                '你很善良': 'You are kind',
                '你很刻薄': 'You are mean',
                '你很有趣': 'You are funny',
                '你很无聊': 'You are boring',
                '你很好': 'You are nice',
                '你很坏': 'You are bad',
                '不客气': 'You are welcome',
                '谢谢': 'Thank you',
                '请': 'Please',
                '对不起': 'Sorry',
                '打扰一下': 'Excuse me',
                '保佑你': 'Bless you',
                '恭喜': 'Congratulations',
                '祝你好运': 'Good luck',
                '玩得开心': 'Have fun',
                '尽情享受': 'Enjoy yourself',
                '保重': 'Take care',
                '小心': 'Be careful',
                '别担心': 'Don\'t worry',
                '冷静下来': 'Calm down',
                '放松': 'Relax',
                '快点': 'Hurry up',
                '慢一点': 'Slow down',
                '等等': 'Wait',
                '停下': 'Stop',
                '走': 'Go',
                '来': 'Come',
                '留下': 'Stay',
                '离开': 'Leave',
                '帮助': 'Help',
                '保存': 'Save',
                '删除': 'Delete',
                '复制': 'Copy',
                '粘贴': 'Paste',
                '剪切': 'Cut',
                '撤销': 'Undo',
                '重做': 'Redo',
                '打印': 'Print',
                '下载': 'Download',
                '上传': 'Upload',
                '打开': 'Open',
                '关闭': 'Close',
                '保存': 'Save',
                '退出': 'Exit',
                '登录': 'Log in',
                '登出': 'Log out',
                '注册': 'Sign up',
                '登录': 'Sign in',
                '忘记密码': 'Forgot password',
                '修改密码': 'Change password',
                '个人资料': 'Profile',
                '设置': 'Settings',
                '偏好设置': 'Preferences',
                '语言': 'Language',
                '主题': 'Theme',
                '深色模式': 'Dark mode',
                '浅色模式': 'Light mode',
                '通知': 'Notifications',
                '消息': 'Messages',
                '收件箱': 'Inbox',
                '发件箱': 'Outbox',
                '已发送': 'Sent',
                '草稿': 'Draft',
                '垃圾箱': 'Trash',
                '垃圾邮件': 'Spam',
                '归档': 'Archive',
                '搜索': 'Search',
                '筛选': 'Filter',
                '排序': 'Sort',
                '刷新': 'Refresh',
                '重新加载': 'Reload',
                '首页': 'Home',
                '仪表盘': 'Dashboard',
                '个人资料': 'Profile',
                '设置': 'Settings',
                '帮助': 'Help',
                '支持': 'Support',
                '联系我们': 'Contact us',
                '关于我们': 'About us',
                '隐私政策': 'Privacy policy',
                '服务条款': 'Terms of service',
                '登出': 'Logout',
                '登录': 'Login',
                '注册': 'Register',
                '提交': 'Submit',
                '取消': 'Cancel',
                '确认': 'Confirm',
                '同意': 'Agree',
                '不同意': 'Disagree',
                '接受': 'Accept',
                '拒绝': 'Decline',
                '是': 'Yes',
                '否': 'No',
                '也许': 'Maybe',
                '好的': 'Ok',
                '好的': 'Fine',
                '太好了': 'Great',
                '太棒了': 'Wonderful',
                '优秀': 'Excellent',
                '令人惊叹': 'Amazing',
                '糟糕': 'Terrible',
                '可怕': 'Awful',
                '恐怖': 'Horrible',
                '极好的': 'Fantastic',
                '卓越的': 'Superb',
                '壮丽的': 'Magnificent',
                '奇妙的': 'Marvelous',
                '杰出的': 'Outstanding',
                '例外的': 'Exceptional',
                '非凡的': 'Extraordinary',
                '显著的': 'Remarkable',
                '令人印象深刻的': 'Impressive',
                '美妙的': 'Wonderful',
                '可爱的': 'Lovely',
                '好的': 'Nice',
                '好的': 'Good',
                '坏的': 'Bad',
                '差的': 'Poor',
                '一般的': 'Average',
                '公平的': 'Fair',
                '优秀的': 'Excellent',
                '完美的': 'Perfect',
                '不完美的': 'Imperfect',
                '完整的': 'Complete',
                '不完整的': 'Incomplete',
                '满的': 'Full',
                '空的': 'Empty',
                '大的': 'Big',
                '小的': 'Small',
                '大的': 'Large',
                '微小的': 'Tiny',
                '巨大的': 'Huge',
                '庞大的': 'Enormous',
                '巨大的': 'Gigantic',
                '大规模的': 'Massive',
                '极小的': 'Minuscule',
                '高的': 'Tall',
                '矮的': 'Short',
                '长的': 'Long',
                '宽的': 'Wide',
                '窄的': 'Narrow',
                '深的': 'Deep',
                '浅的': 'Shallow',
                '厚的': 'Thick',
                '薄的': 'Thin',
                '重的': 'Heavy',
                '轻的': 'Light',
                '硬的': 'Hard',
                '软的': 'Soft',
                '粗糙的': 'Rough',
                '光滑的': 'Smooth',
                '锋利的': 'Sharp',
                '钝的': 'Blunt',
                '热的': 'Hot',
                '冷的': 'Cold',
                '温暖的': 'Warm',
                '凉爽的': 'Cool',
                '湿的': 'Wet',
                '干的': 'Dry',
                '干净的': 'Clean',
                '脏的': 'Dirty',
                '整洁的': 'Tidy',
                '凌乱的': 'Messy',
                '整洁的': 'Neat',
                '混乱的': 'Disorganized',
                '有组织的': 'Organized',
                '新的': 'New',
                '旧的': 'Old',
                '年轻的': 'Young',
                '老的': 'Old',
                '新鲜的': 'Fresh',
                '陈的': 'Stale',
                '好的': 'Good',
                '坏的': 'Bad',
                '好的': 'Nice',
                '刻薄的': 'Mean',
                '善良的': 'Kind',
                '残忍的': 'Cruel',
                '友好的': 'Friendly',
                '不友好的': 'Unfriendly',
                '有礼貌的': 'Polite',
                '粗鲁的': 'Rude',
                '诚实的': 'Honest',
                '不诚实的': 'Dishonest',
                '真实的': 'Truthful',
                '说谎的': 'Lying',
                '忠诚的': 'Loyal',
                '不忠诚的': 'Disloyal',
                '忠实的': 'Faithful',
                '不忠实的': 'Unfaithful',
                '值得信赖的': 'Trustworthy',
                '不值得信赖的': 'Untrustworthy',
                '可靠的': 'Reliable',
                '不可靠的': 'Unreliable',
                '可依赖的': 'Dependable',
                '不可依赖的': 'Undependable',
                '负责任的': 'Responsible',
                '不负责任的': 'Irresponsible',
                '小心的': 'Careful',
                '粗心的': 'Careless',
                '谨慎的': 'Cautious',
                '鲁莽的': 'Reckless',
                '勇敢的': 'Brave',
                '胆小的': 'Cowardly',
                '大胆的': 'Bold',
                '胆小的': 'Timid',
                '自信的': 'Confident',
                '不安全的': 'Insecure',
                '自豪的': 'Proud',
                '谦虚的': 'Humble',
                '傲慢的': 'Arrogant',
                '谦虚的': 'Modest',
                '自负的': 'Conceited',
                '慷慨的': 'Generous',
                '吝啬的': 'Stingy',
                '善良的': 'Kind',
                '自私的': 'Selfish',
                '体贴的': 'Thoughtful',
                '轻率的': 'Thoughtless',
                '考虑周到的': 'Considerate',
                '不考虑他人的': 'Inconsiderate',
                '有帮助的': 'Helpful',
                '无帮助的': 'Unhelpful',
                '合作的': 'Cooperative',
                '不合作的': 'Uncooperative',
                '友好的': 'Friendly',
                '敌对的': 'Hostile',
                '和平的': 'Peaceful',
                '暴力的': 'Violent',
                '平静的': 'Calm',
                '激动的': 'Agitated',
                '放松的': 'Relaxed',
                '紧张的': 'Stressed',
                '快乐的': 'Happy',
                '悲伤的': 'Sad',
                '欢乐的': 'Joyful',
                '痛苦的': 'Miserable',
                '兴奋的': 'Excited',
                '无聊的': 'Bored',
                '热情的': 'Enthusiastic',
                '冷漠的': 'Apathetic',
                '热情的': 'Passionate',
                '漠不关心的': 'Indifferent',
                '活泼的': 'Lively',
                'dull的': 'Dull',
                '精力充沛的': 'Energetic',
                '疲倦的': 'Tired',
                '活跃的': 'Active',
                '不活跃的': 'Inactive',
                '警觉的': 'Alert',
                '困倦的': 'Sleepy',
                '醒着的': 'Wakeful',
                '睡着的': 'Asleep',
                '意识到的': 'Aware',
                '未意识到的': 'Unaware',
                '有意识的': 'Conscious',
                '无意识的': 'Unconscious',
                '聪明的': 'Smart',
                '愚蠢的': 'Stupid',
                '聪明的': 'Intelligent',
                '无知的': 'Ignorant',
                '聪明的': 'Clever',
                '愚蠢的': 'Foolish',
                '明智的': 'Wise',
                '傻的': 'Silly',
                '杰出的': 'Brilliant',
                '哑的': 'Dumb',
                '天才的': 'Genius',
                '白痴的': 'Idiot',
                '创造性的': 'Creative',
                '缺乏想象力的': 'Unimaginative',
                '原创的': 'Original',
                '衍生的': 'Derivative',
                '创新的': 'Innovative',
                '传统的': 'Conventional',
                '独特的': 'Unique',
                '常见的': 'Common',
                '特殊的': 'Special',
                '普通的': 'Ordinary',
                '稀有的': 'Rare',
                '频繁的': 'Frequent',
                '稀少的': 'Scarce',
                '丰富的': 'Plentiful',
                '丰富的': 'Abundant',
                '有限的': 'Limited',
                '无限的': 'Unlimited',
                '足够的': 'Sufficient',
                '不足的': 'Insufficient',
                '足够的': 'Adequate',
                '不足的': 'Inadequate',
                '过量的': 'Excess',
                '不足的': 'Deficient',
                '更多的': 'More',
                '更少的': 'Less',
                '最多的': 'Most',
                '最少的': 'Least',
                '许多的': 'Many',
                '很少的': 'Few',
                '许多的': 'Much',
                '很少的': 'Little',
                '一些的': 'Some',
                '没有的': 'None',
                '所有的': 'All',
                '整个的': 'Whole',
                '部分的': 'Partial',
                '完整的': 'Complete',
                '不完整的': 'Incomplete',
                '总的': 'Total',
                '部分的': 'Partial',
                '每个的': 'Every',
                '每个的': 'Each',
                '任何的': 'Any',
                '任一的': 'Either',
                '两者都不的': 'Neither',
                '两者都的': 'Both',
                '几个的': 'Several',
                '各种各样的': 'Various',
                '不同的': 'Different',
                '相同的': 'Same',
                '相似的': 'Similar',
                '不相似的': 'Dissimilar',
                '相似的': 'Alike',
                '不相似的': 'Unlike',
                '相同的': 'Identical',
                '不同的': 'Distinct',
                '分开的': 'Separate',
                '连接的': 'Connected',
                '连接的': 'Joined',
                '分离的': 'Detached',
                '附加的': 'Attached',
                '自由的': 'Free',
                '受限制的': 'Restricted',
                '开放的': 'Open',
                '关闭的': 'Closed',
                '可访问的': 'Accessible',
                '不可访问的': 'Inaccessible',
                '可用的': 'Available',
                '不可用的': 'Unavailable',
                '准备好的': 'Ready',
                '未准备好的': 'Unready',
                '愿意的': 'Willing',
                '不愿意的': 'Unwilling',
                '渴望的': 'Eager',
                '不情愿的': 'Reluctant',
                '焦虑的': 'Anxious',
                '平静的': 'Calm',
                '担心的': 'Worried',
                '放松的': 'Relaxed',
                '紧张的': 'Nervous',
                '自信的': 'Confident',
                '害怕的': 'Afraid',
                '勇敢的': 'Brave',
                '害怕的': 'Fearful',
                '大胆的': 'Bold',
                '胆小的': 'Timid',
                '害羞的': 'Shy',
                '外向的': 'Outgoing',
                '内向的': 'Introverted',
                '外向的': 'Extroverted',
                '社交的': 'Sociable',
                '不社交的': 'Unsociable',
                '友好的': 'Friendly',
                '不友好的': 'Unfriendly',
                '善良的': 'Kind',
                '不善良的': 'Unkind',
                '好的': 'Nice',
                '刻薄的': 'Mean',
                '愉快的': 'Pleasant',
                '不愉快的': 'Unpleasant',
                '快乐的': 'Happy',
                '悲伤的': 'Sad',
                '高兴的': 'Glad',
                '抱歉的': 'Sorry',
                '高兴的': 'Delighted',
                '失望的': 'Disappointed',
                '高兴的': 'Pleased',
                '不高兴的': 'Displeased',
                '满意的': 'Satisfied',
                '不满意的': 'Unsatisfied',
                '满足的': 'Content',
                '不满的': 'Discontent',
                '感激的': 'Grateful',
                '忘恩负义的': 'Ungrateful',
                '感谢的': 'Thankful',
                '不感谢的': 'Unthankful',
                '幸运的': 'Lucky',
                '不幸的': 'Unlucky',
                '幸运的': 'Fortunate',
                '不幸的': 'Unfortunate',
                '成功的': 'Successful',
                '不成功的': 'Unsuccessful',
                '繁荣的': 'Prosperous',
                '贫穷的': 'Poor',
                '富有的': 'Rich',
                '富有的': 'Wealthy',
                '贫困的': 'Needy',
                '慷慨的': 'Generous',
                '吝啬的': 'Stingy',
                '自由主义的': 'Liberal',
                '保守的': 'Conservative',
                '温和的': 'Moderate',
                '极端的': 'Extreme',
                '激进的': 'Radical',
                '反动的': 'Reactionary',
                '进步的': 'Progressive',
                '落后的': 'Backward',
                '现代的': 'Modern',
                '传统的': 'Traditional',
                '过时的': 'Old-fashioned',
                '时尚的': 'Fashionable',
                '过时的': 'Outdated',
                '当前的': 'Current',
                '过时的': 'Obsolete',
                '新的': 'New',
                '旧的': 'Old',
                '年轻的': 'Young',
                '老的': 'Old',
                '新鲜的': 'Fresh',
                '陈的': 'Stale',
                '原创的': 'Original',
                '复制的': 'Copy',
                '真正的': 'Genuine',
                '假的': 'Fake',
                '真实的': 'Real',
                '想象的': 'Imaginary',
                '真实的': 'Authentic',
                '伪造的': 'Counterfeit',
                '自然的': 'Natural',
                '人工的': 'Artificial',
                '有机的': 'Organic',
                '合成的': 'Synthetic',
                '纯净的': 'Pure',
                '不纯的': 'Impure',
                '干净的': 'Clean',
                '脏的': 'Dirty',
                '清晰的': 'Clear',
                '多云的': 'Cloudy',
                '透明的': 'Transparent',
                '不透明的': 'Opaque',
                '明亮的': 'Bright',
                '黑暗的': 'Dark',
                '轻的': 'Light',
                '重的': 'Heavy',
                '软的': 'Soft',
                '硬的': 'Hard',
                '光滑的': 'Smooth',
                '粗糙的': 'Rough',
                '湿的': 'Wet',
                '干的': 'Dry',
                '热的': 'Hot',
                '冷的': 'Cold',
                '温暖的': 'Warm',
                '凉爽的': 'Cool',
                '锋利的': 'Sharp',
                '钝的': 'Blunt',
                '尖的': 'Pointed',
                '圆的': 'Rounded',
                '平的': 'Flat',
                '弯曲的': 'Curved',
                '直的': 'Straight',
                '弯曲的': 'Crooked',
                '窄的': 'Narrow',
                '宽的': 'Wide',
                '厚的': 'Thick',
                '薄的': 'Thin',
                '短的': 'Short',
                '长的': 'Long',
                '高的': 'Tall',
                '低的': 'Low',
                '深的': 'Deep',
                '浅的': 'Shallow',
                '小的': 'Small',
                '大的': 'Large',
                '微小的': 'Tiny',
                '巨大的': 'Huge',
                '庞大的': 'Enormous',
                '巨大的': 'Gigantic',
                '大规模的': 'Massive',
                '极小的': 'Minuscule',
                '平均的': 'Average',
                '正常的': 'Normal',
                '标准的': 'Standard',
                '常规的': 'Regular',
                '常见的': 'Common',
                '普通的': 'Ordinary',
                '通常的': 'Usual',
                '典型的': 'Typical',
                '不寻常的': 'Unusual',
                '稀有的': 'Rare',
                '奇怪的': 'Strange',
                '奇怪的': 'Odd',
                '特殊的': 'Peculiar',
                '独特的': 'Unique',
                '不同的': 'Different',
                '怪异的': 'Weird',
                '奇异的': 'Bizarre',
                '异常的': 'Abnormal',
                '不规则的': 'Irregular',
                '非常规的': 'Unconventional',
                '非正统的': 'Unorthodox',
                '替代的': 'Alternative',
                '传统的': 'Traditional',
                '传统的': 'Conventional',
                '正统的': 'Orthodox',
                '正式的': 'Formal',
                '非正式的': 'Informal',
                '随意的': 'Casual',
                '严肃的': 'Serious',
                '好玩的': 'Playful',
                '专业的': 'Professional',
                '业余的': 'Amateur',
                '专家的': 'Expert',
                '新手的': 'Novice',
                '熟练的': 'Skilled',
                '不熟练的': 'Unskilled',
                '有经验的': 'Experienced',
                '缺乏经验的': 'Inexperienced',
                '合格的': 'Qualified',
                '不合格的': 'Unqualified',
                '有能力的': 'Competent',
                '无能力的': 'Incompetent',
                '高效的': 'Efficient',
                '低效的': 'Inefficient',
                '有效的': 'Effective',
                '无效的': 'Ineffective',
                '多产的': 'Productive',
                '不生产的': 'Unproductive',
                '有用的': 'Useful',
                '无用的': 'Useless',
                '有价值的': 'Valuable',
                '无价值的': 'Worthless',
                '有益的': 'Beneficial',
                '有害的': 'Harmful',
                '有帮助的': 'Helpful',
                '有害的': 'Harmful',
                '积极的': 'Positive',
                '消极的': 'Negative',
                '好的': 'Good',
                '坏的': 'Bad',
                '正确的': 'Right',
                '错误的': 'Wrong',
                '真实的': 'True',
                '假的': 'False',
                '正确的': 'Correct',
                '不正确的': 'Incorrect',
                '准确的': 'Accurate',
                '不准确的': 'Inaccurate',
                '精确的': 'Precise',
                '不精确的': 'Imprecise',
                '确切的': 'Exact',
                '不确切的': 'Inexact',
                '具体的': 'Specific',
                '一般的': 'General',
                '详细的': 'Detailed',
                '模糊的': 'Vague',
                '清晰的': 'Clear',
                '不清楚的': 'Unclear',
                '明显的': 'Obvious',
                '隐藏的': 'Hidden',
                '明显的': 'Apparent',
                '微妙的': 'Subtle',
                '明显的': 'Evident',
                '秘密的': 'Secret',
                '公共的': 'Public',
                '私人的': 'Private',
                '机密的': 'Confidential',
                '开放的': 'Open',
                '关闭的': 'Closed',
                '已知的': 'Known',
                '未知的': 'Unknown',
                '熟悉的': 'Familiar',
                '不熟悉的': 'Unfamiliar',
                '可识别的': 'Recognizable',
                '不可识别的': 'Unrecognizable',
                '相似的': 'Similar',
                '不同的': 'Different',
                '相同的': 'Same',
                '相似的': 'Alike',
                '不相似的': 'Unlike',
                '相同的': 'Identical',
                '不同的': 'Distinct',
                '分开的': 'Separate',
                '连接的': 'Connected',
                '连接的': 'Joined',
                '分离的': 'Detached',
                '附加的': 'Attached',
                '自由的': 'Free',
                '受限制的': 'Restricted',
                '开放的': 'Open',
                '关闭的': 'Closed',
                '可访问的': 'Accessible',
                '不可访问的': 'Inaccessible',
                '可用的': 'Available',
                '不可用的': 'Unavailable',
                '准备好的': 'Ready',
                '未准备好的': 'Unready',
                '愿意的': 'Willing',
                '不愿意的': 'Unwilling',
                '渴望的': 'Eager',
                '不情愿的': 'Reluctant',
                '焦虑的': 'Anxious',
                '平静的': 'Calm',
                '担心的': 'Worried',
                '放松的': 'Relaxed',
                '紧张的': 'Nervous',
                '自信的': 'Confident',
                '害怕的': 'Afraid',
                '勇敢的': 'Brave',
                '害怕的': 'Fearful',
                '大胆的': 'Bold',
                '胆小的': 'Timid',
                '害羞的': 'Shy',
                '外向的': 'Outgoing',
                '内向的': 'Introverted',
                '外向的': 'Extroverted',
                '社交的': 'Sociable',
                '不社交的': 'Unsociable',
                '友好的': 'Friendly',
                '不友好的': 'Unfriendly',
                '善良的': 'Kind',
                '不善良的': 'Unkind',
                '好的': 'Nice',
                '刻薄的': 'Mean',
                '愉快的': 'Pleasant',
                '不愉快的': 'Unpleasant',
                '快乐的': 'Happy',
                '悲伤的': 'Sad',
                '高兴的': 'Glad',
                '抱歉的': 'Sorry',
                '高兴的': 'Delighted',
                '失望的': 'Disappointed',
                '高兴的': 'Pleased',
                '不高兴的': 'Displeased',
                '满意的': 'Satisfied',
                '不满意的': 'Unsatisfied',
                '满足的': 'Content',
                '不满的': 'Discontent',
                '感激的': 'Grateful',
                '忘恩负义的': 'Ungrateful',
                '感谢的': 'Thankful',
                '不感谢的': 'Unthankful',
                '幸运的': 'Lucky',
                '不幸的': 'Unlucky',
                '幸运的': 'Fortunate',
                '不幸的': 'Unfortunate',
                '成功的': 'Successful',
                '不成功的': 'Unsuccessful',
                '繁荣的': 'Prosperous',
                '贫穷的': 'Poor',
                '富有的': 'Rich',
                '富有的': 'Wealthy',
                '贫困的': 'Needy',
                '慷慨的': 'Generous',
                '吝啬的': 'Stingy',
                '自由主义的': 'Liberal',
                '保守的': 'Conservative',
                '温和的': 'Moderate',
                '极端的': 'Extreme',
                '激进的': 'Radical',
                '反动的': 'Reactionary',
                '进步的': 'Progressive',
                '落后的': 'Backward',
                '现代的': 'Modern',
                '传统的': 'Traditional',
                '过时的': 'Old-fashioned',
                '时尚的': 'Fashionable',
                '过时的': 'Outdated',
                '当前的': 'Current',
                '过时的': 'Obsolete'
            };
            
            // Check if exact translation exists
            if (translations[text]) {
                return translations[text];
            }
            
            // Default fallback
            return `[Google Translation] English translation of ${text}. This is a mock translation. In a real application, this would call a real translation API.`;
        }

        function mockDeepLTranslationToChinese(text) {
            // Similar to Google but with DeepL branding
            if (text.toLowerCase().includes('hello')) {
                return text.replace(/hello/gi, '你好') + ' (由DeepL翻译)';
            }
            return `[DeepL 翻译] ${text} 的中文翻译结果。DeepL以其高质量的翻译而闻名。`;
        }

        function mockDeepLTranslationToEnglish(text) {
            return `[DeepL Translation] English translation of ${text}. DeepL is known for its high-quality translations.`;
        }

        function mockBaiduTranslationToChinese(text) {
            // Similar to Google but with Baidu branding
            if (text.toLowerCase().includes('hello')) {
                return text.replace(/hello/gi, '你好') + ' (由百度翻译)';
            }
            return `[百度翻译] ${text} 的中文翻译结果。百度翻译针对中文语言对进行了优化。`;
        }

        function mockBaiduTranslationToEnglish(text) {
            return `[Baidu Translation] English translation of ${text}. Baidu Translation is optimized for Chinese language pairs.`;
        }

        // Event Listeners
        translateButton.addEventListener('click', () => {
            const text = sourceText.value.trim();
            if (text) {
                const sourceLang = sourceLanguage.value;
                const targetLang = targetLanguage.value;
                const engine = translationEngine.value;
                translateText(text, sourceLang, targetLang, engine);
            }
        });

        clearSource.addEventListener('click', () => {
            sourceText.value = '';
            updateCharacterCount();
            togglePlaceholder();
        });

        clearTarget.addEventListener('click', () => {
            translationResult.innerHTML = '';
            translationPlaceholder.classList.remove('hidden');
        });

        copySource.addEventListener('click', () => {
            sourceText.select();
            document.execCommand('copy');
            showNotification('Text copied to clipboard');
        });

        copyTarget.addEventListener('click', () => {
            const text = translationResult.innerText;
            navigator.clipboard.writeText(text).then(() => {
                showNotification('Translation copied to clipboard');
            });
        });

        pasteSource.addEventListener('click', () => {
            navigator.clipboard.readText().then(text => {
                sourceText.value = text;
                updateCharacterCount();
                togglePlaceholder();
            });
        });

        listenTarget.addEventListener('click', () => {
            const text = translationResult.innerText;
            const lang = targetLanguage.value;
            speakText(text, lang);
        });

        swapLanguages.addEventListener('click', () => {
            const sourceLang = sourceLanguage.value;
            const targetLang = targetLanguage.value;
            
            sourceLanguage.value = targetLang;
            targetLanguage.value = sourceLang;
            
            const sourceTextValue = sourceText.value;
            const translationText = translationResult.innerText;
            
            sourceText.value = translationText;
            translationResult.innerHTML = sourceTextValue;
            
            updateCharacterCount();
            togglePlaceholder();
            
            if (sourceText.value.trim() === '') {
                translationPlaceholder.classList.remove('hidden');
                translationResult.innerHTML = '';
            } else {
                translationPlaceholder.classList.add('hidden');
            }
        });

        // Text selection for popup translation
        sourceText.addEventListener('mouseup', () => {
            const selection = window.getSelection();
            const selectedText = selection.toString().trim();
            
            if (selectedText.length > 0) {
                const rect = selection.getRangeAt(0).getBoundingClientRect();
                showTranslationPopup(selectedText, rect);
            }
        });

        function showTranslationPopup(text, rect) {
            const sourceLang = sourceLanguage.value === 'auto' ? 'en' : sourceLanguage.value;
            const targetLang = targetLanguage.value;
            const engine = translationEngine.value;
            
            // Position the popup
            translationPopup.style.top = `${rect.bottom + window.scrollY + 10}px`;
            translationPopup.style.left = `${rect.left + window.scrollX}px`;
            
            // Show loading
            popupContent.innerHTML = '<div class="skeleton h-4 w-full mb-2 rounded"></div><div class="skeleton h-4 w-3/4 rounded"></div>';
            translationPopup.style.display = 'block';
            
            // Simulate translation
            setTimeout(() => {
                let translatedText = '';
                
                if (engine === 'google') {
                    if (targetLang === 'zh') {
                        translatedText = mockGoogleTranslationToChinese(text);
                    } else {
                        translatedText = mockGoogleTranslationToEnglish(text);
                    }
                } else if (engine === 'deepl') {
                    if (targetLang === 'zh') {
                        translatedText = mockDeepLTranslationToChinese(text);
                    } else {
                        translatedText = mockDeepLTranslationToEnglish(text);
                    }
                } else if (engine === 'baidu') {
                    if (targetLang === 'zh') {
                        translatedText = mockBaiduTranslationToChinese(text);
                    } else {
                        translatedText = mockBaiduTranslationToEnglish(text);
                    }
                }
                
                popupContent.textContent = translatedText;
            }, 500);
        }

        closePopup.addEventListener('click', () => {
            translationPopup.style.display = 'none';
        });

        // Close popup when clicking outside
        document.addEventListener('click', (e) => {
            if (!translationPopup.contains(e.target) && e.target !== sourceText) {
                translationPopup.style.display = 'none';
            }
        });

        // Text-to-speech functionality
        function speakText(text, lang) {
            if ('speechSynthesis' in window) {
                const utterance = new SpeechSynthesisUtterance(text);
                utterance.lang = lang === 'zh' ? 'zh-CN' : 'en-US';
                speechSynthesis.speak(utterance);
            } else {
                showNotification('Text-to-speech not supported in your browser');
            }
        }

        // File upload functionality
        fileInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                if (file.size > 10 * 1024 * 1024) { // 10MB limit
                    showNotification('File too large. Maximum size is 10MB', 'error');
                    return;
                }
                
                fileName.textContent = file.name;
                fileSize.textContent = formatFileSize(file.size);
                
                // Set appropriate icon based on file type
                const fileType = file.name.split('.').pop().toLowerCase();
                if (fileType === 'pdf') {
                    fileIcon.className = 'fa fa-file-pdf-o text-2xl text-red-500 mr-3';
                } else if (fileType === 'doc' || fileType === 'docx') {
                    fileIcon.className = 'fa fa-file-word-o text-2xl text-blue-500 mr-3';
                } else if (fileType === 'txt') {
                    fileIcon.className = 'fa fa-file-text-o text-2xl text-gray-500 mr-3';
                } else {
                    fileIcon.className = 'fa fa-file-o text-2xl text-gray-500 mr-3';
                }
                
                fileInfo.classList.remove('hidden');
                translateFileButton.disabled = false;
            }
        });

        removeFile.addEventListener('click', () => {
            fileInput.value = '';
            fileInfo.classList.add('hidden');
            translateFileButton.disabled = true;
            fileTranslationResult.classList.add('hidden');
        });

        translateFileButton.addEventListener('click', () => {
            const file = fileInput.files[0];
            if (!file) return;
            
            const startTime = new Date();
            translateFileButton.disabled = true;
            translateFileButton.innerHTML = '<i class="fa fa-spinner fa-spin mr-2"></i> Translating...';
            
            // Simulate file translation based on file type
            const fileType = file.name.split('.').pop().toLowerCase();
            const sourceLang = fileSourceLanguage.value;
            const targetLang = fileTargetLanguage.value;
            
            setTimeout(() => {
                const endTime = new Date();
                const translationTimeSeconds = ((endTime - startTime) / 1000).toFixed(1);
                
                translatedFileName.textContent = `Translated_${file.name}`;
                translationTime.textContent = `Translation completed in ${translationTimeSeconds} seconds`;
                
                // Mock preview based on file type
                let previewContent = '';
                if (fileType === 'pdf') {
                    previewContent = `<p class="mb-2">这是一个PDF文件的翻译预览。</p><p>文件包含${Math.floor(Math.random() * 50) + 10}页，已成功翻译。</p><p class="mt-2">翻译质量：优秀</p>`;
                } else if (fileType === 'doc' || fileType === 'docx') {
                    previewContent = `<p class="mb-2">这是一个Word文档的翻译预览。</p><p>文档包含${Math.floor(Math.random() * 20) + 5}段文字，已成功翻译。</p><p class="mt-2">翻译质量：优秀</p>`;
                } else if (fileType === 'txt') {
                    previewContent = `<p class="mb-2">这是一个文本文件的翻译预览。</p><p>文件包含约${Math.floor(Math.random() * 1000) + 100}个单词，已成功翻译。</p><p class="mt-2">翻译质量：优秀</p>`;
                } else {
                    previewContent = `<p>文件已成功翻译。</p>`;
                }
                
                fileTranslationPreview.innerHTML = previewContent;
                fileTranslationResult.classList.remove('hidden');
                
                translateFileButton.disabled = false;
                translateFileButton.innerHTML = '<i class="fa fa-file-text-o mr-2"></i> Translate Document';
                
                // Scroll to result
                fileTranslationResult.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }, 2000);
        });

        downloadTranslatedFile.addEventListener('click', () => {
            const file = fileInput.files[0];
            if (!file) return;
            
            const fileName = `Translated_${file.name}`;
            const fileType = file.name.split('.').pop().toLowerCase();
            
            // Create a dummy blob for demo purposes
            let content = '';
            let mimeType = 'text/plain';
            
            if (fileType === 'pdf') {
                content = '%PDF-1.4\n% Demo PDF content\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\nendobj\n4 0 obj\n<< /Length 44 >>\nstream\nBT /F1 24 Tf 100 700 Td (This is a translated PDF document) Tj ET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000010 00000 n \n0000000053 00000 n \n0000000096 00000 n \n0000000145 00000 n \ntrailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n200\n%%EOF';
                mimeType = 'application/pdf';
            } else if (fileType === 'doc' || fileType === 'docx') {
                content = 'This is a mock translated Word document content.';
                mimeType = 'application/msword';
            } else {
                content = '这是一个翻译后的文本文件内容。\nThis is a translated text file content.';
            }
            
            const blob = new Blob([content], { type: mimeType });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            
            showNotification('File downloaded successfully');
        });

        // Helper Functions
        function formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        function showNotification(message, type = 'success') {
            const notification = document.createElement('div');
            notification.className = `fixed bottom-4 right-4 px-4 py-2 rounded-lg shadow-lg transition-opacity duration-300 ${type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'}`;
            notification.textContent = message;
            
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.opacity = '0';
                setTimeout(() => {
                    document.body.removeChild(notification);
                }, 300);
            }, 3000);
        }

        // Initialize the app
        function init() {
            updateCharacterCount();
            togglePlaceholder();
            
            // Set up resizable panels
            const grip = document.querySelector('.grip');
            const sourcePanel = document.querySelector('.flex-1.flex.flex-col.border-r');
            const container = document.querySelector('.flex.flex-col.md\\:flex-row');
            
            let isResizing = false;
            
            grip.addEventListener('mousedown', (e) => {
                isResizing = true;
                document.addEventListener('mousemove', handleMouseMove);
                document.addEventListener('mouseup', stopResizing);
                e.preventDefault();
            });
            
            function handleMouseMove(e) {
                if (!isResizing) return;
                
                const containerRect = container.getBoundingClientRect();
                const newWidth = ((e.clientX - containerRect.left) / containerRect.width) * 100;
                
                // Limit the minimum and maximum width
                if (newWidth > 20 && newWidth < 80) {
                    sourcePanel.style.flex = `0 0 ${newWidth}%`;
                }
            }
            
            function stopResizing() {
                isResizing = false;
                document.removeEventListener('mousemove', handleMouseMove);
                document.removeEventListener('mouseup', stopResizing);
            }
        }

        // Call init function when DOM is loaded
        document.addEventListener('DOMContentLoaded', init);
    </script>
</body>
</html>