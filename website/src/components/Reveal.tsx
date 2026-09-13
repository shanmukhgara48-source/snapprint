import React, { useRef } from 'react';
import { motion, useInView, useTransform, useReducedMotion } from 'framer-motion';
import { useAntiGravity } from './antiGravity/useAntiGravity';

interface RevealProps {
  children: React.ReactNode;
  delay?: number;
  className?: string;
  intensity?: number;
}

export function Reveal({ children, delay = 0, className = '', intensity = 1 }: RevealProps) {
  const ref = useRef<HTMLDivElement>(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });
  const prefersReducedMotion = useReducedMotion();
  const { smoothVelocity } = useAntiGravity();

  // Create a parallax/offset effect based on scroll velocity
  const yOffset = useTransform(smoothVelocity, [-1000, 1000], [-15 * intensity, 15 * intensity]);

  if (prefersReducedMotion) {
    return <div className={className}>{children}</div>;
  }

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 30, scale: 0.98 }}
      animate={isInView ? { opacity: 1, y: 0, scale: 1 } : { opacity: 0, y: 30, scale: 0.98 }}
      transition={{
        type: 'spring',
        stiffness: 100,
        damping: 20,
        delay: delay / 1000,
      }}
      className={className}
      style={{ y: isInView ? yOffset : 0 }}
    >
      {children}
    </motion.div>
  );
}
