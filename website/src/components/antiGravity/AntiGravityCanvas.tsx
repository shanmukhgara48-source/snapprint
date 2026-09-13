import React, { useEffect, useRef } from 'react';
import { useReducedMotion } from 'framer-motion';

/**
 * AntiGravityCanvas renders a subtle layer of floating particles
 * that drift slowly and react slightly to scroll/mouse.
 * 
 * Uses HTML5 Canvas and requestAnimationFrame for high-performance rendering.
 */
export const AntiGravityCanvas: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const prefersReducedMotion = useReducedMotion();

  useEffect(() => {
    if (prefersReducedMotion) return;

    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationFrameId: number;
    let particles: Array<{
      x: number;
      y: number;
      radius: number;
      vx: number;
      vy: number;
      alpha: number;
    }> = [];
    let running = true;

    // Fewer particles on small / low-power screens; pause when hidden.
    const isCoarse =
      typeof window !== 'undefined' &&
      window.matchMedia?.('(pointer: coarse)').matches;
    const isSmall =
      typeof window !== 'undefined' && window.innerWidth < 768;
    const particleCount = isSmall || isCoarse ? 16 : 40;
    const baseSpeed = 0.2;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    };

    const initParticles = () => {
      particles = Array.from({ length: particleCount }).map(() => ({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        radius: Math.random() * 1.5 + 0.5,
        vx: (Math.random() - 0.5) * baseSpeed,
        vy: -Math.random() * baseSpeed - 0.1, // Float upwards
        alpha: Math.random() * 0.4 + 0.1,
      }));
    };

    const draw = () => {
      if (!running) return;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      particles.forEach((p) => {
        // Move
        p.x += p.vx;
        p.y += p.vy;

        // Wrap around
        if (p.y < 0) {
          p.y = canvas.height;
          p.x = Math.random() * canvas.width;
        }
        if (p.x < 0) p.x = canvas.width;
        if (p.x > canvas.width) p.x = 0;
        if (p.y > canvas.height) p.y = 0;

        // Draw
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(212, 175, 55, ${p.alpha})`; // gold tint
        ctx.fill();
      });

      animationFrameId = requestAnimationFrame(draw);
    };

    window.addEventListener('resize', resize);
    const onVisibility = () => {
      const hidden = document.hidden;
      if (hidden && running) {
        running = false;
        cancelAnimationFrame(animationFrameId);
      } else if (!hidden && !running) {
        running = true;
        draw();
      }
    };
    document.addEventListener('visibilitychange', onVisibility);
    resize();
    draw();

    return () => {
      window.removeEventListener('resize', resize);
      document.removeEventListener('visibilitychange', onVisibility);
      cancelAnimationFrame(animationFrameId);
    };
  }, [prefersReducedMotion]);

  if (prefersReducedMotion) {
    return null;
  }

  return (
    <canvas
      ref={canvasRef}
      className="pointer-events-none fixed inset-0 z-[-1] opacity-60"
      style={{
        background: 'transparent',
      }}
    />
  );
};
