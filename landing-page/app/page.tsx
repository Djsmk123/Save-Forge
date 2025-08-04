'use client'

import { motion } from 'framer-motion'
import { 
  Gamepad2, 
  Users, 
  RefreshCw, 
  Rocket, 
  Download, 
  Star, 
  Shield, 
  Zap,
  CheckCircle,
  ArrowRight,
  Coffee,
  Heart
} from 'lucide-react'

export default function Home() {
  return (
    <div className="min-h-screen">
      {/* Navigation */}
      <nav className="fixed top-0 w-full bg-dark-100/80 backdrop-blur-md z-50 border-b border-dark-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-2">
              <Gamepad2 className="h-8 w-8 text-primary-400" />
              <span className="text-xl font-bold gradient-text">Save Forge</span>
            </div>
            <div className="hidden md:flex items-center space-x-8">
              <a href="#features" className="text-dark-400 hover:text-primary-400 transition-colors">Features</a>
              <a href="#download" className="text-dark-400 hover:text-primary-400 transition-colors">Download</a>
              <a href="#about" className="text-dark-400 hover:text-primary-400 transition-colors">About</a>
              <a href="#support" className="text-dark-400 hover:text-primary-400 transition-colors">Support</a>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="hero-gradient pt-24 pb-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
            >
              <h1 className="text-5xl md:text-7xl font-bold text-balance mb-6">
                Manage Your
                <span className="gradient-text block">Game Saves</span>
                Like Never Before
              </h1>
              <p className="text-xl text-dark-400 max-w-3xl mx-auto mb-8 text-balance">
                Save Forge is a powerful desktop application for managing multiple save profiles for games. 
                Perfect for households with multiple players who want to easily switch between different save states.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <a href="#download" className="btn-primary inline-flex items-center">
                  <Download className="mr-2 h-5 w-5" />
                  Download for Windows
                </a>
                <a href="#features" className="btn-outline inline-flex items-center">
                  Learn More
                  <ArrowRight className="ml-2 h-5 w-5" />
                </a>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-dark-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold mb-4 text-dark-600">Powerful Features</h2>
            <p className="text-xl text-dark-400 max-w-2xl mx-auto">
              Everything you need to manage your game saves efficiently
            </p>
          </motion.div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                icon: Gamepad2,
                title: "Game Management",
                description: "Add games with custom names and icons. Configure save game directories and set optional game executable paths for direct launching.",
                features: ["Custom game names", "Game icons", "Save directories", "Executable paths"]
              },
              {
                icon: Users,
                title: "Profile Management",
                description: "Create multiple save profiles per game with automatic default profile creation and visual distinction between profiles.",
                features: ["Multiple profiles", "Default profiles", "Profile renaming", "Visual distinction"]
              },
              {
                icon: RefreshCw,
                title: "Profile Switching",
                description: "Switch between save profiles with one click. Automatic backup of current saves before switching with status indicators.",
                features: ["One-click switching", "Automatic backup", "Status indicators", "Sync capabilities"]
              },
              {
                icon: Rocket,
                title: "Game Launching",
                description: "Launch games directly from the app with automatic profile switching before game launch and error handling.",
                features: ["Direct launching", "Auto profile switching", "Error handling", "Seamless integration"]
              },
              {
                icon: Shield,
                title: "Data Protection",
                description: "Your save data is protected with automatic backups and safe switching mechanisms to prevent data loss.",
                features: ["Automatic backups", "Safe switching", "Data protection", "Recovery options"]
              },
              {
                icon: Zap,
                title: "Fast Performance",
                description: "Lightning-fast profile switching and game launching with optimized performance for the best user experience.",
                features: ["Fast switching", "Quick launching", "Optimized performance", "Smooth experience"]
              }
            ].map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="card p-6"
              >
                <div className="w-12 h-12 bg-primary-900/20 rounded-lg flex items-center justify-center mb-4">
                  <feature.icon className="h-6 w-6 text-primary-400" />
                </div>
                <h3 className="text-xl font-semibold mb-3 text-dark-600">{feature.title}</h3>
                <p className="text-dark-400 mb-4">{feature.description}</p>
                <ul className="space-y-2">
                  {feature.features.map((item, idx) => (
                    <li key={idx} className="flex items-center text-sm text-dark-500">
                      <CheckCircle className="h-4 w-4 text-primary-400 mr-2 flex-shrink-0" />
                      {item}
                    </li>
                  ))}
                </ul>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section id="download" className="py-20 feature-gradient">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <h2 className="text-4xl font-bold mb-4 text-dark-600">Ready to Get Started?</h2>
            <p className="text-xl text-dark-400 max-w-2xl mx-auto mb-8">
              Download Save Forge and start managing your game saves like a pro
            </p>
            
            <div className="bg-dark-100 rounded-2xl shadow-2xl p-8 max-w-2xl mx-auto border border-dark-200">
              <div className="flex items-center justify-center mb-6">
                <Gamepad2 className="h-16 w-16 text-primary-400 mr-4" />
                <div className="text-left">
                  <h3 className="text-2xl font-bold text-dark-600">Save Forge</h3>
                  <p className="text-dark-400">Version 1.0.0+1</p>
                </div>
              </div>
              
              <div className="space-y-4 mb-8">
                <div className="flex items-center justify-between p-4 bg-dark-200 rounded-lg">
                  <span className="font-medium text-dark-400">Platform</span>
                  <span className="text-primary-400 font-semibold">Windows 10/11</span>
                </div>
                <div className="flex items-center justify-between p-4 bg-dark-200 rounded-lg">
                  <span className="font-medium text-dark-400">Size</span>
                  <span className="text-primary-400 font-semibold">~50 MB</span>
                </div>
                <div className="flex items-center justify-between p-4 bg-dark-200 rounded-lg">
                  <span className="font-medium text-dark-400">Requirements</span>
                  <span className="text-primary-400 font-semibold">Flutter Runtime</span>
                </div>
              </div>
              
              <div className="flex flex-col sm:flex-row gap-4">
                  <button className="btn-primary flex-1 flex items-center justify-center gap-2" onClick={() => {
                    window.open('https://github.com/djsmk123/save-forge/releases/', '_blank');
                  }}>
                    <Download className="h-5 w-5" />
                    <span>Download Installer</span>
                  </button>
                  <button
                  className="btn-outline flex-1 flex items-center justify-center gap-2"
                  onClick={() => {
                    window.open('https://github.com/djsmk123/save-forge', '_blank');
                  }}
                >
                  <Star className="h-5 w-5" />
                  <span>View Source Code</span>
                </button>
              </div>
              
                            <p className="text-sm text-dark-500 mt-4">
                Free to download and use. Open source project.
              </p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Support Section */}
      <section id="support" className="py-20 bg-dark-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <h2 className="text-4xl font-bold mb-4 text-dark-600">Support the Project</h2>
            <p className="text-xl text-dark-400 max-w-2xl mx-auto mb-8">
              If you find Save Forge useful, consider supporting its development
            </p>
            
            <div className="bg-dark-100 rounded-2xl shadow-2xl p-8 max-w-2xl mx-auto border border-dark-300">
              <div className="flex items-center justify-center mb-6">
                <Coffee className="h-16 w-16 text-accent-400 mr-4" />
                <div className="text-left">
                  <h3 className="text-2xl font-bold text-dark-600">Buy Me a Coffee</h3>
                  <p className="text-dark-400">Support the development</p>
                </div>
              </div>
              
              <p className="text-dark-400 mb-6 text-center">
                Save Forge is completely free and open source. If you enjoy using it and want to support its continued development, consider buying me a coffee!
              </p>
              
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <a 
                  href="https://www.buymeacoffee.com/smkwinner" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="btn-secondary inline-flex items-center"
                >
                  <Coffee className="mr-2 h-5 w-5" />
                  Buy Me a Coffee
                </a>
                <a 
                  href="https://github.com/djsmk123/save-forge" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="btn-outline inline-flex items-center"
                >
                  <Heart className="mr-2 h-5 w-5" />
                  Star on GitHub
                </a>
              </div>
              
              <p className="text-sm text-dark-500 mt-4 text-center">
                Every contribution helps keep the project alive and improving!
              </p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* About Section */}
      <section id="about" className="py-20 bg-dark-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <h2 className="text-4xl font-bold mb-4 text-dark-600">About Save Forge</h2>
            <p className="text-xl text-dark-400 max-w-3xl mx-auto mb-8">
              Save Forge is built with modern technologies to provide the best experience for managing game saves.
            </p>
            
                         <div className="grid md:grid-cols-3 gap-8 mt-12">
               <div className="text-center">
                 <div className="w-16 h-16 bg-primary-900/20 rounded-full flex items-center justify-center mx-auto mb-4">
                   <Zap className="h-8 w-8 text-primary-400" />
                 </div>
                 <h3 className="text-xl font-semibold mb-2 text-dark-600">Built with Flutter</h3>
                 <p className="text-dark-400">Modern cross-platform framework for smooth performance</p>
               </div>
               
               <div className="text-center">
                 <div className="w-16 h-16 bg-secondary-900/20 rounded-full flex items-center justify-center mx-auto mb-4">
                   <Shield className="h-8 w-8 text-secondary-400" />
                 </div>
                 <h3 className="text-xl font-semibold mb-2 text-dark-600">Safe & Secure</h3>
                 <p className="text-dark-400">Your save data is protected with automatic backups</p>
               </div>
               
               <div className="text-center">
                 <div className="w-16 h-16 bg-accent-900/20 rounded-full flex items-center justify-center mx-auto mb-4">
                   <Users className="h-8 w-8 text-accent-400" />
                 </div>
                 <h3 className="text-xl font-semibold mb-2 text-dark-600">Family Friendly</h3>
                 <p className="text-dark-400">Perfect for households with multiple players</p>
               </div>
             </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-dark-50 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-4">
              <Gamepad2 className="h-8 w-8 text-primary-400" />
              <span className="text-xl font-bold text-dark-600">Save Forge</span>
            </div>
            <p className="text-dark-400 mb-4">
              Manage your game saves with ease
            </p>
            <div className="flex justify-center space-x-6 text-sm text-dark-500">
              <a href="https://github.com/djsmk123/save-forge" className="hover:text-primary-400 transition-colors">GitHub</a>
              <a href="https://www.buymeacoffee.com/smkwinner" className="hover:text-primary-400 transition-colors">Support</a>
            </div>
            <p className="text-xs text-dark-600 mt-6">
              © 2024 Save Forge. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
} 