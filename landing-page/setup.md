# Setup Guide for Save Forge Landing Page

## Quick Start

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Run the development server:**
   ```bash
   npm run dev
   ```

3. **Open your browser:**
   Navigate to [http://localhost:3000](http://localhost:3000)

## Troubleshooting

### If CSS is not working:

1. **Check if all dependencies are installed:**
   ```bash
   npm install
   ```

2. **Clear Next.js cache:**
   ```bash
   rm -rf .next
   npm run dev
   ```

3. **Verify PostCSS configuration:**
   Make sure `postcss.config.js` exists and contains:
   ```js
   module.exports = {
     plugins: {
       tailwindcss: {},
       autoprefixer: {},
     },
   }
   ```

4. **Check Tailwind configuration:**
   Make sure `tailwind.config.js` exists and has the correct content paths.

### If TypeScript errors occur:

1. **Install TypeScript:**
   ```bash
   npm install -D typescript @types/node @types/react @types/react-dom
   ```

2. **Generate TypeScript config:**
   ```bash
   npx tsc --init
   ```

### If animations don't work:

1. **Check Framer Motion installation:**
   ```bash
   npm install framer-motion
   ```

2. **Verify Lucide React:**
   ```bash
   npm install lucide-react
   ```

## File Structure Check

Make sure you have these files:
- ✅ `package.json`
- ✅ `next.config.js`
- ✅ `tailwind.config.js`
- ✅ `postcss.config.js`
- ✅ `tsconfig.json`
- ✅ `app/layout.tsx`
- ✅ `app/page.tsx`
- ✅ `app/globals.css`
- ✅ `public/manifest.json`

## Common Issues

1. **"Module not found" errors**: Run `npm install` again
2. **CSS not loading**: Clear `.next` folder and restart dev server
3. **TypeScript errors**: Make sure `tsconfig.json` exists and is valid
4. **Build errors**: Check that all required files are present

## Development Tips

- Use `npm run dev` for development
- Use `npm run build` to test production build
- Use `npm run lint` to check for code issues
- The site will auto-reload when you make changes 