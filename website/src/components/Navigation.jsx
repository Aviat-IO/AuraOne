import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Github, Sun, Moon } from 'lucide-react'

const Navigation = ({ isDark, toggleDarkMode }) => {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  return (
    <motion.nav
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.5 }}
      className={`fixed top-0 w-full z-50 transition-all duration-300 ${
        scrolled
          ? 'glass-effect soft-shadow-lg py-4'
          : 'bg-transparent py-6'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center">
          <div className="flex items-center space-x-2">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary animate-pulse-soft" />
            <span className="text-2xl font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface">
              Aura One
            </span>
          </div>

          <div className="flex items-center space-x-4">
            <a
              href="https://github.com/Aviat-IO/AuraOne"
              target="_blank"
              rel="noopener noreferrer"
              className="p-2 rounded-lg hover:bg-aura-light-surface-high dark:hover:bg-aura-dark-surface-high transition-colors"
              aria-label="View on GitHub"
            >
              <Github className="w-5 h-5 text-aura-light-on-surface dark:text-aura-dark-on-surface" />
            </a>

            <button
              onClick={toggleDarkMode}
              className="p-2 rounded-lg hover:bg-aura-light-surface-high dark:hover:bg-aura-dark-surface-high transition-colors"
              aria-label="Toggle dark mode"
            >
              {isDark ? (
                <Sun className="w-5 h-5 text-aura-dark-on-surface" />
              ) : (
                <Moon className="w-5 h-5 text-aura-light-on-surface" />
              )}
            </button>
          </div>
        </div>
      </div>
    </motion.nav>
  )
}

export default Navigation