/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.html',  // Incluye todos los archivos HTML dentro de la carpeta 'pages'
    './js/**/*.js'        // Incluye todos los archivos JavaScript dentro de la carpeta 'js'
  ],
  theme: {
    extend: {
      colors: {
        'green-400': '#10B981',
        'indigo-500': '#4F46E5',
        'indigo-600': '#4338CA',
        'red-500': '#EF4444',
        'gray-800': '#1F2937',
        'gray-900': '#111827',
      }
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        brightTheme: {
          'primary': '#4F46E5',  // Azul eléctrico
          'secondary': '#10B981', // Verde neón
          'accent': '#EF4444',    // Rojo brillante
          'neutral': '#1F2937',   // Gris oscuro
          'base-100': '#ffffff',  // Fondo blanco
          'info': '#2094f3',
          'success': '#32a852',
          'warning': '#ffcc00',
          'error': '#e63946',
        },
      },
    ],
  },
}
