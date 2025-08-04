# Save Forge Landing Page

A modern, responsive landing page for the Save Forge game save profile manager application. Built with Next.js, TypeScript, Tailwind CSS, and Framer Motion.

## Features

- 🎨 **Modern Design** - Clean, professional design with optimized color theme
- 📱 **Responsive** - Fully responsive across all devices
- ⚡ **Fast Performance** - Optimized for speed and SEO
- 🎭 **Smooth Animations** - Beautiful animations with Framer Motion
- 🔍 **SEO Optimized** - Complete meta tags, Open Graph, and structured data
- 🎯 **Conversion Focused** - Clear call-to-actions and download section

## Tech Stack

- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first CSS framework
- **Framer Motion** - Animation library
- **Lucide React** - Beautiful icons
- **Inter Font** - Modern typography

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd landing-page
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Run the development server**
   ```bash
   npm run dev
   # or
   yarn dev
   ```

4. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## Project Structure

```
landing-page/
├── app/
│   ├── globals.css          # Global styles and Tailwind config
│   ├── layout.tsx           # Root layout with SEO metadata
│   └── page.tsx             # Main landing page
├── public/
│   ├── manifest.json        # PWA manifest
│   └── favicon.ico          # Site favicon
├── tailwind.config.js       # Tailwind configuration
├── next.config.js           # Next.js configuration
└── package.json             # Dependencies and scripts
```

## Customization

### Colors
The color theme is defined in `tailwind.config.js`:
- **Primary**: Blue gradient (#0ea5e9)
- **Secondary**: Purple gradient (#d946ef)
- **Accent**: Orange gradient (#f97316)
- **Dark**: Gray scale for text and backgrounds

### Content
Update the content in `app/page.tsx`:
- Hero section text and CTAs
- Feature descriptions and icons
- Download section details
- About section information

### SEO
Modify SEO settings in `app/layout.tsx`:
- Meta tags and descriptions
- Open Graph data
- Twitter Card information
- Google verification codes

## Deployment

### Vercel (Recommended)
1. Push your code to GitHub
2. Connect your repository to Vercel
3. Deploy automatically

### Other Platforms
```bash
# Build the project
npm run build

# Start production server
npm start
```

## SEO Features

- ✅ Complete meta tags
- ✅ Open Graph images
- ✅ Twitter Card support
- ✅ Structured data
- ✅ Sitemap generation
- ✅ Robots.txt
- ✅ Canonical URLs
- ✅ Performance optimization

## Performance

- ✅ Image optimization
- ✅ Font optimization
- ✅ Code splitting
- ✅ Lazy loading
- ✅ Compression
- ✅ Caching headers

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## License

This project is licensed under the MIT License. 