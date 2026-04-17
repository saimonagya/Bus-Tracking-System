import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        accent: {
          50: "#f0fdf4",
          100: "#dcfce7",
          200: "#bbf7d0",
          300: "#86efac",
          400: "#4ade80",
          500: "#22c55e",
          600: "#10b981",
          700: "#15803d",
          800: "#166534",
          900: "#14532d"
        }
      },
      fontFamily: {
        sans: ["Segoe UI", "system-ui", "sans-serif"]
      },
      boxShadow: {
        panel: "0 20px 45px rgba(15, 23, 42, 0.16)",
        card: "0 12px 32px rgba(15, 23, 42, 0.08)"
      }
    }
  },
  plugins: []
};

export default config;
