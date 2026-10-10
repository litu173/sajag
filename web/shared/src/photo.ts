/** Responsive sources for a report photo. Unsplash sample photos support on-the-fly resizing. */
export interface PhotoSources {
  src: string;
  srcSet?: string;
  /** Tiny, heavily compressed version shown blurred while the real image loads. */
  placeholder?: string;
}

const widths = [240, 480, 800, 1200, 1800];

export function photoSources(url: string, width = 1200): PhotoSources {
  if (!url.startsWith('https://images.unsplash.com/')) return { src: url };
  const at = (w: number, q = 72) => `${url}?w=${w}&q=${q}&auto=format&fit=crop`;
  return {
    src: at(width),
    srcSet: widths.map((w) => `${at(w)} ${w}w`).join(', '),
    placeholder: at(32, 30),
  };
}
