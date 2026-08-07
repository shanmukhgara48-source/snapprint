import type { AnchorHTMLAttributes, MouseEvent } from "react";
import { navigate } from "../lib/router";

interface LinkProps extends AnchorHTMLAttributes<HTMLAnchorElement> {
  to: string;
}

export function Link({ to, onClick, ...props }: LinkProps) {
  function follow(event: MouseEvent<HTMLAnchorElement>) {
    onClick?.(event);
    if (
      event.defaultPrevented ||
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      props.target
    ) {
      return;
    }
    event.preventDefault();
    navigate(to);
  }

  return <a {...props} href={to} onClick={follow} />;
}
