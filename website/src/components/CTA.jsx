import { motion } from 'framer-motion'
import { Sparkles, ArrowRight } from 'lucide-react'

const CTA = () => {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="relative"
        >
          {/* Background gradient */}
          <div className="absolute inset-0 bg-gradient-to-r from-aura-light-primary via-aura-light-secondary to-aura-light-tertiary dark:from-aura-dark-primary dark:via-aura-dark-secondary dark:to-aura-dark-tertiary rounded-3xl blur-3xl opacity-30" />

          {/* Card content */}
          <div className="relative bg-gradient-to-br from-aura-light-primary-container to-aura-light-tertiary-container dark:from-aura-dark-primary-container dark:to-aura-dark-tertiary-container rounded-3xl p-8 md:p-12 soft-shadow-lg">
            <div className="text-center">
              {/* Icon */}
              <motion.div
                animate={{
                  rotate: [0, 10, -10, 0],
                }}
                transition={{
                  duration: 4,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
                className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-white/20 dark:bg-black/20 backdrop-blur-sm mb-6"
              >
                <Sparkles className="w-8 h-8 text-white" />
              </motion.div>

              <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
                Start Your Journey Today
              </h2>

              <p className="text-lg text-white/90 mb-8 max-w-2xl mx-auto">
                Join thousands who are already capturing their lives effortlessly.
                Your memories are waiting to be preserved.
              </p>

              {/* Email signup (placeholder) */}
              <div className="max-w-md mx-auto mb-6">
                <div className="flex flex-col sm:flex-row gap-3">
                  <input
                    type="email"
                    placeholder="Enter your email for updates"
                    className="flex-1 px-4 py-3 rounded-xl bg-white/20 backdrop-blur-sm text-white placeholder:text-white/60 border border-white/20 focus:outline-none focus:border-white/40"
                  />
                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="px-6 py-3 rounded-xl bg-white text-aura-light-primary dark:text-aura-dark-primary font-semibold flex items-center justify-center space-x-2 hover:bg-white/90 transition-colors"
                  >
                    <span>Get Early Access</span>
                    <ArrowRight className="w-4 h-4" />
                  </motion.button>
                </div>
                <p className="text-xs text-white/60 mt-3">
                  We'll notify you when Aura One launches. No spam, ever.
                </p>
              </div>

              {/* Alternative CTAs */}
              <div className="flex flex-wrap justify-center gap-4">
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className="px-6 py-3 rounded-xl bg-white/10 backdrop-blur-sm text-white border border-white/20 font-medium hover:bg-white/20 transition-colors"
                >
                  App Store (Coming Soon)
                </motion.button>

                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className="px-6 py-3 rounded-xl bg-white/10 backdrop-blur-sm text-white border border-white/20 font-medium hover:bg-white/20 transition-colors"
                >
                  Google Play (Coming Soon)
                </motion.button>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default CTA