import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight } from 'lucide-react'

// Placeholder screenshots - replace with actual screenshots
const screenshots = [
  {
    id: 1,
    title: "Daily Summary",
    description: "AI-generated summaries of your day",
    image: "https://picsum.photos/400/800?random=1",
    gradient: "from-aura-light-primary to-aura-light-secondary"
  },
  {
    id: 2,
    title: "Location Timeline",
    description: "Track your journey throughout the day",
    image: "https://picsum.photos/400/800?random=2",
    gradient: "from-aura-light-secondary to-aura-light-tertiary"
  },
  {
    id: 3,
    title: "Photo Gallery",
    description: "Your memories beautifully organized",
    image: "https://picsum.photos/400/800?random=3",
    gradient: "from-aura-light-tertiary to-aura-light-primary"
  },
  {
    id: 4,
    title: "Voice Editing",
    description: "Edit entries with natural voice commands",
    image: "https://picsum.photos/400/800?random=4",
    gradient: "from-aura-light-primary to-aura-light-tertiary"
  }
]

const Screenshots = () => {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [mouseY, setMouseY] = useState(0)

  useEffect(() => {
    const handleMouseMove = (e) => {
      setMouseY((e.clientY - window.innerHeight / 2) * 0.02)
    }
    window.addEventListener('mousemove', handleMouseMove)
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [])

  const nextSlide = () => {
    setCurrentIndex((prev) => (prev + 1) % screenshots.length)
  }

  const prevSlide = () => {
    setCurrentIndex((prev) => (prev - 1 + screenshots.length) % screenshots.length)
  }

  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 overflow-hidden">
      <div className="max-w-7xl mx-auto">
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold mb-4">
            <span className="text-aura-light-on-surface dark:text-aura-dark-on-surface">
              Beautiful & Intuitive
            </span>
          </h2>
          <p className="text-xl text-aura-light-on-surface/70 dark:text-aura-dark-on-surface/70 max-w-2xl mx-auto">
            Designed with care to make journaling a delightful experience
          </p>
        </motion.div>

        <div className="relative">
          {/* Phone mockup container */}
          <div className="relative mx-auto max-w-sm">
            {/* Decorative background elements */}
            <motion.div
              style={{ transform: `translateY(${mouseY}px)` }}
              className="absolute -top-20 -left-20 w-40 h-40 bg-gradient-to-br from-aura-light-primary/30 to-aura-light-secondary/30 dark:from-aura-dark-primary/30 dark:to-aura-dark-secondary/30 rounded-full blur-3xl"
            />
            <motion.div
              style={{ transform: `translateY(${-mouseY}px)` }}
              className="absolute -bottom-20 -right-20 w-40 h-40 bg-gradient-to-br from-aura-light-tertiary/30 to-aura-light-primary/30 dark:from-aura-dark-tertiary/30 dark:to-aura-dark-primary/30 rounded-full blur-3xl"
            />

            {/* Phone frame */}
            <div className="relative mx-auto w-[300px] h-[600px] bg-gradient-to-br from-gray-800 to-gray-900 rounded-[3rem] p-3 soft-shadow-lg">
              <div className="absolute top-1/2 left-0 w-1 h-16 -translate-y-1/2 bg-gray-700 rounded-r-lg" />
              <div className="absolute top-1/2 right-0 w-1 h-16 -translate-y-1/2 bg-gray-700 rounded-l-lg" />
              <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-black rounded-b-2xl" />

              {/* Screen */}
              <div className="relative w-full h-full bg-black rounded-[2.5rem] overflow-hidden">
                <AnimatePresence mode="wait">
                  <motion.img
                    key={currentIndex}
                    src={screenshots[currentIndex].image}
                    alt={screenshots[currentIndex].title}
                    initial={{ opacity: 0, x: 100 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -100 }}
                    transition={{ duration: 0.3 }}
                    className="w-full h-full object-cover"
                  />
                </AnimatePresence>
              </div>
            </div>

            {/* Navigation buttons */}
            <button
              onClick={prevSlide}
              className="absolute left-0 top-1/2 -translate-y-1/2 -translate-x-16 p-3 rounded-full bg-white/80 dark:bg-aura-dark-surface/80 backdrop-blur-sm soft-shadow hover:scale-110 transition-transform"
              aria-label="Previous screenshot"
            >
              <ChevronLeft className="w-6 h-6 text-aura-light-on-surface dark:text-aura-dark-on-surface" />
            </button>

            <button
              onClick={nextSlide}
              className="absolute right-0 top-1/2 -translate-y-1/2 translate-x-16 p-3 rounded-full bg-white/80 dark:bg-aura-dark-surface/80 backdrop-blur-sm soft-shadow hover:scale-110 transition-transform"
              aria-label="Next screenshot"
            >
              <ChevronRight className="w-6 h-6 text-aura-light-on-surface dark:text-aura-dark-on-surface" />
            </button>
          </div>

          {/* Description */}
          <AnimatePresence mode="wait">
            <motion.div
              key={currentIndex}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
              className="text-center mt-12"
            >
              <h3 className="text-2xl font-semibold text-aura-light-on-surface dark:text-aura-dark-on-surface mb-2">
                {screenshots[currentIndex].title}
              </h3>
              <p className="text-aura-light-on-surface/70 dark:text-aura-dark-on-surface/70">
                {screenshots[currentIndex].description}
              </p>
            </motion.div>
          </AnimatePresence>

          {/* Dots indicator */}
          <div className="flex justify-center space-x-2 mt-8">
            {screenshots.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`w-2 h-2 rounded-full transition-all duration-300 ${
                  index === currentIndex
                    ? 'w-8 bg-gradient-to-r from-aura-light-primary to-aura-light-tertiary dark:from-aura-dark-primary dark:to-aura-dark-tertiary'
                    : 'bg-gray-400 dark:bg-gray-600'
                }`}
                aria-label={`Go to screenshot ${index + 1}`}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}

export default Screenshots