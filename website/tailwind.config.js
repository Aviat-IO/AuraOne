/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Light theme colors - warm and peaceful
        'aura-light': {
          'primary': '#E8A87C',
          'on-primary': '#FFFFFF',
          'primary-container': '#FFF0E5',
          'on-primary-container': '#5D4037',
          'secondary': '#F4C2A1',
          'on-secondary': '#FFFFFF',
          'secondary-container': '#FFF5F0',
          'on-secondary-container': '#6D4C41',
          'tertiary': '#D4A574',
          'on-tertiary': '#FFFFFF',
          'tertiary-container': '#FFF8F3',
          'on-tertiary-container': '#5D4E37',
          'surface': '#FFFBF7',
          'on-surface': '#4A3C28',
          'surface-high': '#FFF5ED',
          'surface-container': '#FFF2E7',
          'surface-low': '#FFEFE0',
          'outline': '#BCAA97',
          'outline-variant': '#E0D5C7',
        },
        // Dark theme colors - warm and cozy
        'aura-dark': {
          'primary': '#FFB74D',
          'on-primary': '#4E2E00',
          'primary-container': '#6D3F00',
          'on-primary-container': '#FFDDB3',
          'secondary': '#FFAB91',
          'on-secondary': '#5D2E1F',
          'secondary-container': '#7A3F2E',
          'on-secondary-container': '#FFDAD0',
          'tertiary': '#FFD54F',
          'on-tertiary': '#4A3C00',
          'tertiary-container': '#695300',
          'on-tertiary-container': '#FFE8B3',
          'surface': '#1A1410',
          'on-surface': '#F0E6DC',
          'surface-high': '#322A24',
          'surface-container': '#2A221C',
          'surface-low': '#221A15',
          'outline': '#9C8F80',
          'outline-variant': '#4F453A',
        }
      },
      fontFamily: {
        'sans': ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'float-delayed': 'float 6s ease-in-out 3s infinite',
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'fade-in-up': 'fadeInUp 0.6s ease-out',
        'pulse-soft': 'pulseSoft 3s ease-in-out infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-20px)' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeInUp: {
          '0%': {
            opacity: '0',
            transform: 'translateY(20px)'
          },
          '100%': {
            opacity: '1',
            transform: 'translateY(0)'
          },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.8' },
        }
      },
      backdropBlur: {
        xs: '2px',
      }
    },
  },
  plugins: [],
}