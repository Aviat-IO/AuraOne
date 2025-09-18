import { motion } from 'framer-motion'
import { BookOpen, Brain, Shield } from 'lucide-react'

const Hero = () => {
  return (
    <section className="relative min-h-screen flex items-center justify-center px-4 sm:px-6 lg:px-8 overflow-hidden">
      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden">
        <motion.div
          animate={{
            scale: [1, 1.2, 1],
            rotate: [0, 90, 0],
          }}
          transition={{
            duration: 20,
            repeat: Infinity,
            ease: "linear"
          }}
          className="absolute -top-40 -right-40 w-80 h-80 bg-gradient-to-br from-aura-light-primary/20 to-aura-light-secondary/20 dark:from-aura-dark-primary/20 dark:to-aura-dark-secondary/20 rounded-full blur-3xl"
        />
        <motion.div
          animate={{
            scale: [1, 1.3, 1],
            rotate: [0, -90, 0],
          }}
          transition={{
            duration: 25,
            repeat: Infinity,
            ease: "linear"
          }}
          className="absolute -bottom-40 -left-40 w-96 h-96 bg-gradient-to-br from-aura-light-tertiary/20 to-aura-light-primary/20 dark:from-aura-dark-tertiary/20 dark:to-aura-dark-primary/20 rounded-full blur-3xl"
        />
      </div>

      <div className="relative max-w-4xl mx-auto text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <h1 className="text-5xl sm:text-6xl md:text-7xl font-bold mb-6">
            <span className="gradient-text from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary">
              Your Life,
            </span>
            <br />
            <span className="text-aura-light-on-surface dark:text-aura-dark-on-surface">
              Automatically Chronicled
            </span>
          </h1>

          <p className="text-xl md:text-2xl text-aura-light-on-surface/80 dark:text-aura-dark-on-surface/80 mb-12 max-w-2xl mx-auto">
            An AI-powered journaling app that captures your day automatically,
            preserves your memories locally, and helps you discover patterns in your life.
          </p>

          {/* Feature badges */}
          <div className="flex flex-wrap justify-center gap-4 mb-12">
            <motion.div
              whileHover={{ scale: 1.05 }}
              className="flex items-center space-x-2 px-4 py-2 rounded-full bg-aura-light-primary-container dark:bg-aura-dark-primary-container"
            >
              <BookOpen className="w-4 h-4 text-aura-light-on-primary-container dark:text-aura-dark-on-primary-container" />
              <span className="text-sm font-medium text-aura-light-on-primary-container dark:text-aura-dark-on-primary-container">
                Automatic Journaling
              </span>
            </motion.div>

            <motion.div
              whileHover={{ scale: 1.05 }}
              className="flex items-center space-x-2 px-4 py-2 rounded-full bg-aura-light-secondary-container dark:bg-aura-dark-secondary-container"
            >
              <Brain className="w-4 h-4 text-aura-light-on-secondary-container dark:text-aura-dark-on-secondary-container" />
              <span className="text-sm font-medium text-aura-light-on-secondary-container dark:text-aura-dark-on-secondary-container">
                AI-Powered Insights
              </span>
            </motion.div>

            <motion.div
              whileHover={{ scale: 1.05 }}
              className="flex items-center space-x-2 px-4 py-2 rounded-full bg-aura-light-tertiary-container dark:bg-aura-dark-tertiary-container"
            >
              <Shield className="w-4 h-4 text-aura-light-on-tertiary-container dark:text-aura-dark-on-tertiary-container" />
              <span className="text-sm font-medium text-aura-light-on-tertiary-container dark:text-aura-dark-on-tertiary-container">
                100% Private
              </span>
            </motion.div>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="px-8 py-4 rounded-xl bg-gradient-to-r from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary text-white font-semibold text-lg soft-shadow-lg"
            >
              Coming Soon to App Store
            </motion.button>

            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="px-8 py-4 rounded-xl border-2 border-aura-light-outline dark:border-aura-dark-outline text-aura-light-on-surface dark:text-aura-dark-on-surface font-semibold text-lg hover:bg-aura-light-surface-high dark:hover:bg-aura-dark-surface-high transition-colors"
            >
              Coming Soon to Google Play
            </motion.button>
          </div>
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <motion.div
        animate={{ y: [0, 10, 0] }}
        transition={{ duration: 2, repeat: Infinity }}
        className="absolute bottom-8 left-1/2 transform -translate-x-1/2"
      >
        <div className="w-6 h-10 rounded-full border-2 border-aura-light-outline dark:border-aura-dark-outline flex justify-center">
          <div className="w-1 h-3 bg-aura-light-primary dark:bg-aura-dark-primary rounded-full mt-2" />
        </div>
      </motion.div>
    </section>
  )
}

export default Hero