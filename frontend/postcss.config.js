// frontend/tailwind.config.js
module.exports = {
  content: [
    './pages/**/*.{html,js}',
    './components/**/*.{html,js}',
  ],
  theme: {
    extend: {
      colors: {
        primary: '#32a852',
        secondary: '#1d71b8',
        accent: '#f0b500',
        neutral: '#333333',
        background: '#000000',
      },
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        newLife: {
          'primary': '#32a852',
          'secondary': '#1d71b8',
          'accent': '#f0b500',
          'neutral': '#333333',
          'base-100': '#ffffff',
          'info': '#2094f3',
          'success': '#32a852',
          'warning': '#ffcc00',
          'error': '#e63946',
        },
      },
    ],
  },
}
