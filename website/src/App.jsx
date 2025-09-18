import { useState, useEffect } from 'react'
import Hero from './components/Hero'
import Features from './components/Features'
import Privacy from './components/Privacy'
import OpenSource from './components/OpenSource'
import Screenshots from './components/Screenshots'
import CTA from './components/CTA'
import Footer from './components/Footer'
import Navigation from './components/Navigation'

function App() {
  const [isDark, setIsDark] = useState(false)

  useEffect(() => {
    // Check system preference on mount
    const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)')
    setIsDark(darkModeQuery.matches)

    // Apply dark class to document
    if (darkModeQuery.matches) {
      document.documentElement.classList.add('dark')
    }

    // Listen for system preference changes
    const handleChange = (e) => {
      setIsDark(e.matches)
      if (e.matches) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
    }

    darkModeQuery.addEventListener('change', handleChange)
    return () => darkModeQuery.removeEventListener('change', handleChange)
  }, [])

  const toggleDarkMode = () => {
    setIsDark(!isDark)
    document.documentElement.classList.toggle('dark')
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-aura-light-surface via-aura-light-surface-container to-aura-light-primary-container dark:from-aura-dark-surface dark:via-aura-dark-surface-container dark:to-aura-dark-primary-container transition-colors duration-500">
      <Navigation isDark={isDark} toggleDarkMode={toggleDarkMode} />
      <Hero />
      <Features />
      <Screenshots />
      <Privacy />
      <OpenSource />
      <CTA />
      <Footer />
    </div>
  )
}

export default App