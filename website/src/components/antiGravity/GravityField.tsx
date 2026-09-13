import React, { useRef } from 'react';
import type { MouseEvent } from 'react';
import { motion, useSpring, useReducedMotion } from 'framer-motion';

interface GravityFieldProps {
  children: React.ReactNode;
  className?: string;
  pullIntensity?: number; // How strong the pull is (default: 30)
}

/**
 * GravityField creates a magnetic pull effect when the cursor is near.
 * It's perfect for buttons, badges, or small interactive elements.
 */
export const GravityField: React.FC<GravityFieldProps> = ({
  children,
  className = '',
  pullIntensity = 30,
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const prefersReducedMotion = useReducedMotion();

  const x = useSpring(0, { stiffness: 300, damping: 20 });
  const y = useSpring(0, { stiffness: 300, damping: 20 });

  const handleMouseMove = (e: MouseEvent<HTMLDivElement>) => {
    if (!ref.current || prefersReducedMotion) return;
    
    const rect = ref.current.getBoundingClientRect();
    
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    
    // Calculate distance from center
    const distanceX = e.clientX - centerX;
    const distanceY = e.clientY - centerY;
    
    // Normalize and apply intensity
    const moveX = (distanceX / (rect.width / 2)) * pullIntensity;
    const moveY = (distanceY / (rect.height / 2)) * pullIntensity;
    
    x.set(moveX);
    y.set(moveY);
  };

  const handleMouseLeave = () => {
    x.set(0);
    y.set(0);
  };

  if (prefersReducedMotion) {
    return <div className={className}>{children}</div>;
  }

  return (
    <motion.div
      ref={ref}
      className={className}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      style={{
        x,
        y,
      }}
    >
      {children}
    </motion.div>
  );
};
