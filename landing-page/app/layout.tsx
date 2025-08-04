import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Save Forge - Game Save Profile Manager for Windows',
  description: 'Save Forge is a powerful desktop application for managing multiple save profiles for games. Perfect for households with multiple players who want to easily switch between different save states.',
  keywords: 'game save manager, save profiles, game backup, save switching, desktop application, Windows, Flutter',
  authors: [{ name: 'Save Forge Team' }],
  creator: 'Save Forge',
  publisher: 'Save Forge',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://save-forge.com'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'Save Forge - Game Save Profile Manager',
    description: 'Manage multiple save profiles for games with ease. Perfect for households with multiple players.',
    url: 'https://save-forge.com',
    siteName: 'Save Forge',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Save Forge - Game Save Profile Manager',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Save Forge - Game Save Profile Manager',
    description: 'Manage multiple save profiles for games with ease.',
    images: ['/og-image.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  verification: {
    google: 'your-google-verification-code',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className={`${inter.className} antialiased`}>
        {children}
      </body>
    </html>
  )
} 