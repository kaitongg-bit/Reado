# QuickPM Design System Update

## 🎨 New Aesthetic: Liquid Glass
We have upgraded the application UI to a modern **Liquid Glass** design language to provide a premium, "wow" experience.

### Key Features

1.  **Ambient Lighting**:
    - Replaced flat backgrounds with dynamic, blurred ambient orbs (Coral & Blue).
    - Enhances depth and makes the app feel "alive".

2.  **Glassmorphism**:
    - Knowledge Cards now use distinct glass effects:
        - **Blur**: `BackdropFilter` with 10px blur.
        - **Transparency**: Semi-transparent backgrounds (`white/0.08` in dark mode).
        - **Borders**: Thin, semi-transparent borders to define edges.
        - **Shadows**: Soft, diffused shadows for elevation.

3.  **Typography & Hierarchy**:
    - Use of **Inter**-style clean sans-serif fonts.
    - Increased letter spacing (`-0.5`) for headings for a tighter, more professional look.
    - Improved contrast between headings, body text, and metadata.

4.  **Theme System**:
    - Fully responsive **Dark Mode** and **Light Mode**.
    - **Dark Mode**: Deep charcoal backgrounds with glowing accents. Colors pop against the dark canvas.
    - **Light Mode**: Clean, airy interface with high legibility and soft shadows.

### Components Updated
- **Home Tab**: Complete overhaul of the layout, background, and search bar.
- **Knowledge Cards**: Redesigned for visual impact and clarity.
- **Avatar Menu**: Styled with glassmorphism and rounded corners.

### Palette
- **Primary Accent**: Coral (`#FF8A65`) - Used for CTAs and highlights.
- **Secondary Accent**: Blue (`Colors.blueAccent`) - Used for ambient cool tones.
- **Background**: Adaptive (Dark: `#121212`, Light: `#FFFFFF`).
