import React, { useRef, useState } from 'react';
import type { MouseEvent } from 'react';
import { motion, useSpring, useTransform, useReducedMotion } from 'framer-motion';

interface AntiGravityWrapProps {
  children: React.ReactNode;
  className?: string;
  intensity?: number; // How much it tilts (default: 15)
  scaleOnHover?: number; // How much it pops out (default: 1.02)
}

/**
 * AntiGravityWrap provides a 3D hover popout and mouse-tracking tilt effect.
 * It's ideal for cards, buttons, or image containers.
 */
export const AntiGravityWrap: React.FC<AntiGravityWrapProps> = ({
  children,
  className = '',
  intensity = 15,
  scaleOnHover = 1.02,
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const prefersReducedMotion = useReducedMotion();
  const [isHovered, setIsHovered] = useState(false);

  // Mouse position relative to center of the element (-1 to 1)
  const x = useSpring(0, { stiffness: 300, damping: 20 });
  const y = useSpring(0, { stiffness: 300, damping: 20 });

  // Map mouse positions to rotation degrees
  const rotateX = useTransform(y, [-1, 1], [intensity, -intensity]);
  const rotateY = useTransform(x, [-1, 1], [-intensity, intensity]);

  const handleMouseMove = (e: MouseEvent<HTMLDivElement>) => {
    if (!ref.current || prefersReducedMotion) return;
    
    const rect = ref.current.getBoundingClientRect();
    
    // Calculate mouse position relative to the center of the bounding box
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    
    // Normalize to -1 to 1 range
    const normalizedX = (e.clientX - centerX) / (rect.width / 2);
    const normalizedY = (e.clientY - centerY) / (rect.height / 2);
    
    x.set(normalizedX);
    y.set(normalizedY);
  };

  const handleMouseEnter = () => {
    setIsHovered(true);
  };

  const handleMouseLeave = () => {
    setIsHovered(false);
    x.set(0);
    y.set(0);
  };

  if (prefersReducedMotion) {
    return <div className={className}>{children}</div>;
  }

  return (
    <motion.div
      ref={ref}
      className={`relative [perspective:1000px] ${className}`}
      onMouseMove={handleMouseMove}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      <motion.div
        style={{
          rotateX,
          rotateY,
          transformStyle: 'preserve-3d',
        }}
        animate={{
          scale: isHovered ? scaleOnHover : 1,
        }}
        transition={{
          type: 'spring',
          stiffness: 300,
          damping: 20,
        }}
        className="w-full h-full"
      >
        {/* Soft shadow that moves with the tilt */}
        <motion.div 
          className="absolute inset-0 z-[-1] rounded-inherit transition-opacity duration-300 pointer-events-none"
          style={{
            boxShadow: '0 20px 40px -20px rgba(212, 175, 55, 0.15)',
            opacity: isHovered ? 1 : 0,
            transform: 'translateZ(-20px)',
          }}
        />
        {children}
      </motion.div>
    </motion.div>
  );
};
