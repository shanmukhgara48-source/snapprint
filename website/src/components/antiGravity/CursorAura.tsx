import React, { useEffect, useState } from 'react';
import { motion, useSpring, useReducedMotion } from 'framer-motion';

/**
 * CursorAura adds a premium magnetic glow that follows the pointer.
 * Disabled on touch devices and when prefers-reduced-motion is active.
 */
export const CursorAura: React.FC = () => {
  const [isTouch, setIsTouch] = useState(false);
  const prefersReducedMotion = useReducedMotion();
  const [isVisible, setIsVisible] = useState(false);

  // Smooth springs for the cursor follower
  const cursorX = useSpring(-100, { stiffness: 500, damping: 28 });
  const cursorY = useSpring(-100, { stiffness: 500, damping: 28 });
  
  // Slower spring for the trailing aura
  const auraX = useSpring(-100, { stiffness: 100, damping: 20 });
  const auraY = useSpring(-100, { stiffness: 100, damping: 20 });

  useEffect(() => {
    // Detect touch device
    if (window.matchMedia('(hover: none) and (pointer: coarse)').matches) {
      setIsTouch(true);
      return;
    }

    const moveCursor = (e: MouseEvent) => {
      if (!isVisible) setIsVisible(true);
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
      auraX.set(e.clientX);
      auraY.set(e.clientY);
    };

    const handleMouseLeave = () => setIsVisible(false);
    const handleMouseEnter = () => setIsVisible(true);

    window.addEventListener('mousemove', moveCursor);
    document.addEventListener('mouseleave', handleMouseLeave);
    document.addEventListener('mouseenter', handleMouseEnter);

    return () => {
      window.removeEventListener('mousemove', moveCursor);
      document.removeEventListener('mouseleave', handleMouseLeave);
      document.removeEventListener('mouseenter', handleMouseEnter);
    };
  }, [cursorX, cursorY, auraX, auraY, isVisible]);

  if (isTouch || prefersReducedMotion) return null;

  return (
    <div className="pointer-events-none fixed inset-0 z-[9999] overflow-hidden mix-blend-difference">
      {/* Trailing Aura */}
      <motion.div
        className="absolute left-0 top-0 rounded-full"
        style={{
          x: auraX,
          y: auraY,
          width: 80,
          height: 80,
          marginLeft: -40,
          marginTop: -40,
          background: 'radial-gradient(circle, rgba(212, 175, 55, 0.4) 0%, rgba(212, 175, 55, 0) 70%)',
          opacity: isVisible ? 1 : 0,
        }}
        animate={{ opacity: isVisible ? 1 : 0 }}
        transition={{ duration: 0.2 }}
      />
      
      {/* Precision Dot */}
      <motion.div
        className="absolute left-0 top-0 rounded-full bg-white"
        style={{
          x: cursorX,
          y: cursorY,
          width: 6,
          height: 6,
          marginLeft: -3,
          marginTop: -3,
          opacity: isVisible ? 1 : 0,
        }}
      />
    </div>
  );
};
