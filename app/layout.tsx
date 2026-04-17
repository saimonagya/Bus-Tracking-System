import type { Metadata } from "next";

import "./globals.css";

export const metadata: Metadata = {
  title: "City Runner | Bus Tracker",
  description: "Bus tracking and seat management for the Gangtok to Ranipool route."
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
