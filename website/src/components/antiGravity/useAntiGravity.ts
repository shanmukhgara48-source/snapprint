import { useScroll, useVelocity, useSpring, useReducedMotion } from 'framer-motion';

/**
 * useAntiGravity provides scroll-velocity-based parallax or offset values
 * to apply to elements like images, floating cards, or background particles.
 */
export const useAntiGravity = () => {
  const { scrollY } = useScroll();
  const scrollVelocity = useVelocity(scrollY);
  const smoothVelocity = useSpring(scrollVelocity, {
    damping: 50,
    stiffness: 400,
  });
  const prefersReducedMotion = useReducedMotion();

  // Return 0 if reduced motion is preferred
  if (prefersReducedMotion) {
    return { smoothVelocity, offset: 0 };
  }

  return {
    smoothVelocity,
    // You can also add more helpers here based on the velocity
  };
};
