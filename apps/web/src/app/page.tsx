import Image from "next/image";
import { IconArrowUpRight, IconBrandApple, IconBrandGithub, IconShieldLock, IconVolume, IconAdjustmentsHorizontal, IconKeyboard, IconPlus } from "@tabler/icons-react";
import { Brand } from "@/components/brand";
import { PixelKeyboard } from "@/components/pixel-keyboard";
import { AppMockup } from "@/components/app-mockup";
import { Reveal } from "@/components/reveal";
import { download, downloadFilename, repository } from "@/lib/site";

const questions: { question: string; answer: string; guide?: string }[] = [
  { question: "Do I need a mechanical keyboard?", answer: "Just your Mac. strickey adds recorded mechanical switch sounds to your built-in keyboard or any keyboard you already use." },
  { question: "Why does it need Input Monitoring?", answer: "macOS requires it to receive key presses outside the app. strickey uses physical key codes to play sounds. It never records what you type or sends keystrokes anywhere. Secure Input pauses sounds." },
  { question: "Can I use my headphones?", answer: "Yes. strickey follows your Mac's default audio output, including headphones and external speakers. Its own volume slider lets you balance keyboard sounds with everything else." },
  { question: "Is it really free?", answer: "Yes. strickey is open source and free to use. The app is MIT licensed, and the bundled Mechvibes switch recordings include their own license and attribution." },
  { question: "Why does macOS show a security warning?", answer: "The current DMG is not notarized yet. If macOS blocks opening it, follow Apple's guidance for apps from an unidentified developer.", guide: "https://support.apple.com/en-us/102445" },
];

function DownloadLink({ className = "button button-blue", children = "Download for Mac" }: { className?: string; children?: React.ReactNode }) {
  return <a href={download} download={downloadFilename} className={className}><IconBrandApple size={18} stroke={1.8} fill="currentColor" />{children}</a>;
}

export default function Home() {
  return <div id="top">
    <a href="#main" className="skip-link">Skip to content</a>
    <header className="site-header">
      <nav className="nav-shell shell" aria-label="Main navigation">
        <Brand />
        <div className="nav-links"><a href="#features">Features</a><a href="#sounds">Try the sounds</a><a href={repository} target="_blank" rel="noreferrer">GitHub <IconArrowUpRight size={13} /></a></div>
        <DownloadLink className="button button-small button-dark">Get strickey</DownloadLink>
      </nav>
    </header>
    <main id="main">
      <section className="hero shell" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="hero-eyebrow"><IconBrandApple size={14} /> A little joy for your Mac</p>
          <h1 id="hero-title">All the <span>clack.</span><br />None of the keyboard.</h1>
          <p className="hero-description">The sound of your favorite mechanical switches.<br className="desktop-break" /> On the keyboard you already love.</p>
          <div className="hero-actions"><DownloadLink /><a className="text-link" href={repository} target="_blank" rel="noreferrer"><IconBrandGithub size={17} />Free & open source <IconArrowUpRight size={14} /></a></div>
        </div>
        <PixelKeyboard />
      </section>
      <div className="compatibility shell"><span>Made for macOS 14+</span><span>Apple Silicon & Intel</span><span>No extra hardware. Just good sounds.</span></div>
      <section id="features" className="features shell section-space" aria-labelledby="features-title">
        <Reveal><h2 id="features-title">Small app.<br /><span>Big keyboard energy.</span></h2><p className="section-description">A better soundtrack for your everyday typing.<br />Nothing to get between you and your work.</p></Reveal>
        <div className="feature-grid">
          <Reveal className="feature-card feature-app"><div className="feature-copy"><h3>At home in<br />your menu bar.</h3><p>Pick a switch. Set your volume.<br />Get back to whatever you love doing.</p></div><AppMockup /></Reveal>
          <Reveal className="feature-card feature-private"><div className="feature-copy"><h3>Your words<br />stay yours.</h3><p>No accounts. No typing history.<br />Your keystrokes never leave your Mac.</p></div><IconShieldLock className="privacy-art" stroke={0.85} aria-hidden="true" /><a href={repository + "/blob/main/architecture.md"} target="_blank" rel="noreferrer" className="feature-link">See how it works <IconArrowUpRight size={16} /></a></Reveal>
          <Reveal className="feature-card feature-native"><div className="feature-copy"><h3>Same Mac.<br />New feeling.</h3><p>Built with Swift.<br />Made to feel right.</p></div><Image className="pixel-mac" src="/images/pixel-mac.png" alt="An eight-bit silver Mac with a smiling blue screen" width={450} height={375} sizes="(max-width: 767px) 260px, (max-width: 1023px) 220px, 285px" /></Reveal>
        </div>
        <Reveal className="detail-strip">
          <div><IconKeyboard size={21} stroke={1.4} /><h4>Real switches.</h4><p>Recorded Cherry MX Red, Brown, and Blue.</p></div>
          <div><IconAdjustmentsHorizontal size={21} stroke={1.4} /><h4>Your volume.</h4><p>Dial it down. Let it click. Find your balance.</p></div>
          <div><IconVolume size={21} stroke={1.4} /><h4>Where you type.</h4><p>Notes, code, emails. Your everyday soundtrack.</p></div>
        </Reveal>
      </section>
      <section className="setup-section shell section-space" aria-labelledby="setup-title">
        <Reveal className="setup-heading"><h2 id="setup-title">Three little things.<br /><span>Then, happy typing.</span></h2><p className="section-description">No complicated setup. You’re just a few clicks away.</p></Reveal>
        <Reveal className="setup-steps">
          <div><span className="step-number">1</span><h3>Make yourself at home.</h3><p>Download strickey and move it into Applications.</p><a href={download} className="text-link">Get the Mac app</a></div>
          <div><span className="step-number">2</span><h3>Let it listen.</h3><p>Enable Input Monitoring in System Settings, then quit and reopen.</p></div>
          <div><span className="step-number">3</span><h3>Find your favorite click.</h3><p>Pick your switch, set your volume, and type something good.</p></div>
        </Reveal>
      </section>
      <section className="faq-section shell section-space" id="questions" aria-labelledby="faq-title">
        <Reveal className="faq-heading"><h2 id="faq-title">A few good<br /><span>questions.</span></h2><p className="section-description">Anything else?<br /><a href={repository + "/issues"} target="_blank" rel="noreferrer">Ask us on GitHub <IconArrowUpRight size={15} /></a></p></Reveal>
        <div className="faq-list">{questions.map((item) => <details key={item.question}><summary>{item.question}<IconPlus size={20} stroke={1.5} /></summary><p>{item.answer}{item.guide ? <><br /><a href={item.guide} target="_blank" rel="noreferrer" className="text-link">Apple’s installation guidance <IconArrowUpRight size={14} /></a></> : null}</p></details>)}</div>
      </section>
      <section className="download-section shell section-space">
        <Reveal><Image src="/generated/strickey-logo.png" alt="strickey keycap logo" width={82} height={82} /><h2>Make every<br /><span>keystroke feel good.</span></h2><DownloadLink /><p>Free for your Mac. Yours to make your own.</p></Reveal>
      </section>
    </main>
    <footer className="site-footer">
      <div className="footer-shell shell">
        <div className="footer-top"><Brand inverted /><p>A little more click.<br />A little more joy.</p></div>
        <div className="footer-links">
          <div><h3>The app</h3><a href="#features">Features</a><a href="#sounds">Try the sounds</a><a href={download}>Download for Mac</a></div>
          <div><h3>Open source</h3><a href={repository} target="_blank" rel="noreferrer">GitHub <IconArrowUpRight size={14} /></a><a href={repository + "/blob/main/CONTRIBUTING.md"} target="_blank" rel="noreferrer">Contribute</a><a href={repository + "/issues"} target="_blank" rel="noreferrer">Report an issue</a></div>
          <div><h3>The details</h3><a href={repository + "/blob/main/architecture.md"} target="_blank" rel="noreferrer">Architecture</a><a href={repository + "/blob/main/LICENSE"} target="_blank" rel="noreferrer">MIT license</a><a href="/generated/sounds/CREDITS.md">Sound credits</a></div>
          <div className="footer-note"><span>Built for the love of typing.</span><p>No account to create.<br />No subscription to keep.<br />Just you and a very good click.</p></div>
        </div>
        <div className="footer-badges" aria-label="strickey product listings">
          <a className="alternativeto-badge" href="https://alternativeto.net/software/strickey/about/?utm_source=badge&amp;utm_medium=referral" target="_blank" rel="noopener noreferrer" aria-label="strickey on AlternativeTo">
            <img src="https://alternativeto.net/static/badges/badge-compact-dark.svg" alt="strickey | AlternativeTo" width="171" height="58" />
          </a>
          <a className="producthunt-badge" href="https://www.producthunt.com/products/strickey/reviews/new?utm_source=badge-product_review&amp;utm_medium=badge&amp;utm_source=badge-strickey" target="_blank" rel="noopener noreferrer">
            <img src="https://api.producthunt.com/widgets/embed-image/v1/product_review.svg?product_id=1341658&amp;theme=light" alt="strickey - All the clack. None of the keyboard. | Product Hunt" width="250" height="54" />
          </a>
        </div>
        <div className="footer-wordmark" aria-hidden="true">strickey</div>
        <div className="footer-bottom"><a href="https://github.com/madvillax" target="_blank" rel="noreferrer">Made by Mohit Sharma <IconArrowUpRight size={14} /></a><span>Swift at heart. Open by nature.</span></div>
      </div>
    </footer>
  </div>;
}
