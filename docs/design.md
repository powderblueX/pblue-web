# Design notes

PBlue Lab uses an editorial engineering-notebook visual language: strict rules and columns, generous reading space, neutral surfaces, and one functional blue accent. The visual system should support technical content rather than decorate it.

## Typography and spacing

- System sans-serif keeps font loading out of the critical path.
- A system monospace face identifies dates, indexes, tags, and infrastructure-like metadata.
- Display headings use tight tracking and compact line-height; body content remains at least 16px with generous line-height.
- Article content is capped near 70–75 characters per line.
- Major sections use whitespace and borders instead of rounded cards.

## Color and dark mode

Light mode uses a cool gray page and high-contrast ink. Dark mode uses three distinct layers: page, surface, and code. Muted copy stays legible and borders remain visible without becoming bright separators. Blue is reserved for links, focus, and indexing signals.

## Component philosophy

Create a component when it owns behavior or repeats as a meaningful site primitive. Keep one-off editorial composition in its page. Avoid card abstractions, ornamental icons, and wrappers that only rename a `<div>`. Any future page should reuse the same tokens but can choose a different composition when its content demands it.
