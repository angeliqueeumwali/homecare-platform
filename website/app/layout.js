import { AuthProvider } from "@/components/AuthProvider";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import "./globals.css";

export const metadata = {
  title: "Homecare Platform",
  description:
    "Request trusted home services in your neighborhood",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>
          <Navbar />
          <main className="site-main">{children}</main>
          <Footer />
        </AuthProvider>
      </body>
    </html>
  );
}
