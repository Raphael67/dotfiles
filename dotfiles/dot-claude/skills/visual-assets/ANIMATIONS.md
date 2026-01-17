# Animations Reference

Complete reference for Manim, p5.js, and D3.js animations.

---

## Manim

Mathematical Animation Engine for educational videos.

### Basic Structure

```python
from manim import *

class MyScene(Scene):
    def construct(self):
        # Create objects
        circle = Circle()

        # Animate
        self.play(Create(circle))
        self.wait(1)
```

### Mobjects (Mathematical Objects)

#### Shapes
```python
# Basic shapes
Circle(radius=1, color=BLUE)
Square(side_length=2)
Rectangle(width=4, height=2)
Triangle()
Polygon(*vertices)
Line(start=LEFT, end=RIGHT)
Arrow(start=ORIGIN, end=UP)
DoubleArrow(start=LEFT, end=RIGHT)
Dot(point=ORIGIN)
Arc(radius=1, start_angle=0, angle=PI/2)
Ellipse(width=4, height=2)
Annulus(inner_radius=1, outer_radius=2)
```

#### Text
```python
Text("Hello World", font_size=48)
Tex(r"$E = mc^2$")  # LaTeX
MathTex(r"\int_0^1 x^2 dx")
Title("Section Title")
Paragraph("Long text...", alignment="center")
```

#### Groups
```python
VGroup(circle, square)  # Vertical group
HGroup(a, b, c)         # Horizontal group
Group(obj1, obj2)       # Generic group
```

#### Graphs and Plots
```python
# Number plane
plane = NumberPlane()

# Axes
axes = Axes(
    x_range=[-3, 3],
    y_range=[-2, 2],
    axis_config={"include_tip": True}
)

# Function graph
graph = axes.plot(lambda x: x**2, color=BLUE)

# Bar chart
chart = BarChart(
    values=[3, 5, 2, 8],
    bar_names=["A", "B", "C", "D"]
)
```

#### 3D Objects
```python
# Requires ThreeDScene
class My3DScene(ThreeDScene):
    def construct(self):
        sphere = Sphere(radius=1)
        cube = Cube(side_length=2)
        cylinder = Cylinder(radius=0.5, height=2)
        cone = Cone(base_radius=1, height=2)
        torus = Torus(major_radius=2, minor_radius=0.5)
        surface = Surface(
            lambda u, v: [u, v, u**2 + v**2],
            u_range=[-2, 2],
            v_range=[-2, 2]
        )
```

### Animations

#### Creation/Destruction
```python
self.play(Create(circle))       # Draw stroke
self.play(Uncreate(circle))     # Reverse draw
self.play(Write(text))          # Write text
self.play(Unwrite(text))        # Reverse write
self.play(FadeIn(obj))          # Fade in
self.play(FadeOut(obj))         # Fade out
self.play(GrowFromCenter(obj))  # Grow
self.play(ShrinkToCenter(obj))  # Shrink
self.play(DrawBorderThenFill(obj))
self.play(ShowPassingFlash(obj))
```

#### Transforms
```python
self.play(Transform(a, b))              # Morph a into b
self.play(ReplacementTransform(a, b))   # Replace a with b
self.play(TransformFromCopy(a, b))      # Copy a, transform to b
self.play(MoveToTarget(obj))            # Move to obj.target
self.play(ApplyMatrix([[2,0],[0,2]], obj))
```

#### Movement
```python
self.play(obj.animate.shift(RIGHT * 2))
self.play(obj.animate.move_to(UP + LEFT))
self.play(obj.animate.rotate(PI/4))
self.play(obj.animate.scale(2))
self.play(Rotate(obj, PI, axis=UP))
self.play(Circumscribe(obj))
self.play(Indicate(obj))
self.play(Flash(obj))
self.play(Wiggle(obj))
```

#### Timing and Grouping
```python
# Sequential
self.play(Create(a), Create(b))  # Simultaneous

# With lag
self.play(LaggedStart(
    Create(a), Create(b), Create(c),
    lag_ratio=0.5
))

# Animation group
self.play(AnimationGroup(
    Create(a),
    FadeIn(b),
    lag_ratio=0.2
))

# Succession (one after another)
self.play(Succession(
    Create(a),
    Create(b),
    lag_ratio=1.0
))

# Duration and rate
self.play(Create(obj), run_time=2)
self.play(Create(obj), rate_func=smooth)
self.play(Create(obj), rate_func=linear)
self.play(Create(obj), rate_func=rush_into)
```

### Camera

```python
# Move camera
self.play(self.camera.frame.animate.move_to(point))
self.play(self.camera.frame.animate.scale(0.5))

# 3D camera
class My3DScene(ThreeDScene):
    def construct(self):
        self.set_camera_orientation(phi=75*DEGREES, theta=30*DEGREES)
        self.begin_ambient_camera_rotation(rate=0.1)
        self.stop_ambient_camera_rotation()
```

### Colors and Styling

```python
# Built-in colors
BLUE, RED, GREEN, YELLOW, PURPLE, ORANGE, PINK, TEAL
WHITE, BLACK, GRAY, DARK_GRAY, LIGHT_GRAY

# Styling
circle = Circle(
    radius=1,
    color=BLUE,
    fill_color=BLUE,
    fill_opacity=0.5,
    stroke_width=4
)

# Gradients
circle.set_color(color=[RED, BLUE])
```

### CLI Rendering

```bash
# Basic render
manim -pql scene.py MyScene  # Preview, quality low
manim -pqh scene.py MyScene  # Preview, quality high

# Quality flags
-ql  # 480p, 15fps (fast preview)
-qm  # 720p, 30fps (medium)
-qh  # 1080p, 60fps (high)
-qk  # 4K, 60fps (production)

# Output formats
--format=gif
--format=mp4
--format=webm
--format=png  # Frame sequence

# Save location
-o output_name
--media_dir /path/to/output
```

---

## p5.js

Creative coding library for generative art and animations.

### Basic Structure

```javascript
function setup() {
    createCanvas(800, 600);
    // Run once at start
}

function draw() {
    background(220);
    // Runs every frame (60fps default)
}
```

### Shapes

```javascript
// 2D Primitives
point(x, y);
line(x1, y1, x2, y2);
rect(x, y, width, height);
square(x, y, size);
circle(x, y, diameter);
ellipse(x, y, width, height);
triangle(x1, y1, x2, y2, x3, y3);
quad(x1, y1, x2, y2, x3, y3, x4, y4);
arc(x, y, w, h, start, stop);

// Custom shapes
beginShape();
vertex(x1, y1);
vertex(x2, y2);
vertex(x3, y3);
endShape(CLOSE);

// Curves
bezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2);
curve(x1, y1, x2, y2, x3, y3, x4, y4);
```

### Color and Style

```javascript
// Background
background(255);              // Grayscale
background(255, 0, 0);        // RGB
background('#ff0000');        // Hex

// Fill and stroke
fill(255, 0, 0);              // RGB
fill(255, 0, 0, 128);         // RGBA
noFill();
stroke(0);
strokeWeight(2);
noStroke();

// Color modes
colorMode(RGB, 255);
colorMode(HSB, 360, 100, 100);
```

### Transforms

```javascript
// Always use push/pop to isolate transforms
push();
translate(width/2, height/2);
rotate(angle);
scale(2);
// Draw here
pop();

// Rotation
rotate(radians(45));
rotate(PI / 4);

// Matrix operations
applyMatrix(a, b, c, d, e, f);
resetMatrix();
```

### Animation Patterns

```javascript
// Frame-based animation
function draw() {
    let x = sin(frameCount * 0.05) * 100;
}

// Time-based animation
let lastTime = 0;
function draw() {
    let dt = deltaTime / 1000;  // Seconds since last frame
    position += velocity * dt;
}

// Easing
function easeInOut(t) {
    return t < 0.5 ? 2*t*t : -1+(4-2*t)*t;
}

// Oscillation
let y = sin(frameCount * 0.1) * amplitude;

// Noise for organic motion
let x = noise(frameCount * 0.01) * width;
```

### Interaction

```javascript
// Mouse
mouseX, mouseY           // Current position
pmouseX, pmouseY         // Previous position
mouseIsPressed           // Boolean
mouseButton              // LEFT, RIGHT, CENTER

function mousePressed() { }
function mouseReleased() { }
function mouseDragged() { }

// Keyboard
key                      // Last key pressed
keyCode                  // Key code (LEFT_ARROW, etc.)
keyIsPressed             // Boolean

function keyPressed() { }
function keyReleased() { }
```

### 3D (WEBGL Mode)

```javascript
function setup() {
    createCanvas(800, 600, WEBGL);
}

function draw() {
    background(200);
    orbitControl();  // Mouse rotation

    // Lighting
    ambientLight(100);
    pointLight(255, 255, 255, 0, 0, 200);
    directionalLight(255, 0, 0, 0, 0, -1);

    // Materials
    ambientMaterial(255, 0, 0);
    specularMaterial(255);
    shininess(50);

    // 3D shapes
    box(100);
    sphere(50);
    cylinder(50, 200);
    cone(50, 200);
    torus(100, 30);
    plane(200, 200);
}
```

### Export

```javascript
// Save single frame
saveCanvas('myCanvas', 'png');
saveCanvas('myCanvas', 'jpg');

// Save frames for video
function draw() {
    // ... drawing code ...
    if (frameCount <= 60) {
        saveCanvas('frame-' + frameCount, 'png');
    }
}

// Save GIF (requires library)
saveGif('animation', 5);  // 5 seconds
```

### Common Patterns

```javascript
// Grid
for (let y = 0; y < height; y += spacing) {
    for (let x = 0; x < width; x += spacing) {
        circle(x, y, 10);
    }
}

// Particles
class Particle {
    constructor(x, y) {
        this.pos = createVector(x, y);
        this.vel = createVector(random(-1, 1), random(-1, 1));
    }
    update() {
        this.pos.add(this.vel);
    }
    draw() {
        circle(this.pos.x, this.pos.y, 10);
    }
}

// Following mouse
let targetX, targetY;
function draw() {
    targetX = lerp(targetX, mouseX, 0.1);
    targetY = lerp(targetY, mouseY, 0.1);
}

// Rotating around center
push();
translate(centerX, centerY);
rotate(frameCount * 0.01);
rect(-50, -50, 100, 100);
pop();
```

---

## D3.js

Data-Driven Documents for data visualization.

### Core Concepts

#### Selections
```javascript
// Select single element
d3.select('body');
d3.select('#chart');
d3.select('.item');

// Select all matching
d3.selectAll('circle');
d3.selectAll('.bar');
```

#### Data Binding (Enter/Update/Exit)
```javascript
const data = [10, 20, 30, 40];

const circles = svg.selectAll('circle')
    .data(data)
    .join('circle')  // Modern approach
    .attr('r', d => d)
    .attr('cx', (d, i) => i * 50);

// Traditional pattern
const update = svg.selectAll('circle').data(data);
update.enter().append('circle');  // New elements
update.exit().remove();           // Removed elements
update.attr('r', d => d);         // Update existing
```

### Scales

```javascript
// Linear scale
const xScale = d3.scaleLinear()
    .domain([0, 100])      // Data range
    .range([0, width]);    // Pixel range

// Time scale
const timeScale = d3.scaleTime()
    .domain([new Date('2024-01-01'), new Date('2024-12-31')])
    .range([0, width]);

// Ordinal/Band scale (for categories)
const xBand = d3.scaleBand()
    .domain(['A', 'B', 'C', 'D'])
    .range([0, width])
    .padding(0.1);

// Color scales
const colorScale = d3.scaleOrdinal(d3.schemeCategory10);
const sequentialColor = d3.scaleSequential(d3.interpolateBlues)
    .domain([0, 100]);
```

### Axes

```javascript
// Create axes
const xAxis = d3.axisBottom(xScale);
const yAxis = d3.axisLeft(yScale);

// Append to SVG
svg.append('g')
    .attr('transform', `translate(0, ${height - margin.bottom})`)
    .call(xAxis);

svg.append('g')
    .attr('transform', `translate(${margin.left}, 0)`)
    .call(yAxis);

// Customize ticks
xAxis.ticks(5).tickFormat(d3.format('.0%'));
```

### Shapes

```javascript
// Line generator
const line = d3.line()
    .x(d => xScale(d.date))
    .y(d => yScale(d.value))
    .curve(d3.curveMonotoneX);

svg.append('path')
    .datum(data)
    .attr('d', line)
    .attr('fill', 'none')
    .attr('stroke', 'steelblue');

// Area generator
const area = d3.area()
    .x(d => xScale(d.date))
    .y0(height)
    .y1(d => yScale(d.value));

// Arc generator (for pie charts)
const arc = d3.arc()
    .innerRadius(0)
    .outerRadius(radius);

const pie = d3.pie().value(d => d.value);

svg.selectAll('path')
    .data(pie(data))
    .join('path')
    .attr('d', arc);
```

### Transitions

```javascript
// Basic transition
d3.select('circle')
    .transition()
    .duration(750)
    .attr('cx', 100)
    .attr('r', 20);

// Easing
.transition()
    .ease(d3.easeCubic)
    .duration(1000);

// Delay
.transition()
    .delay((d, i) => i * 100)
    .duration(500);

// Chained transitions
selection
    .transition()
    .duration(500)
    .attr('r', 20)
    .transition()
    .duration(500)
    .attr('r', 10);

// On end
.transition()
    .on('end', () => console.log('done'));
```

### Common Chart Patterns

#### Bar Chart
```javascript
const data = [{name: 'A', value: 30}, {name: 'B', value: 50}];

const x = d3.scaleBand()
    .domain(data.map(d => d.name))
    .range([margin.left, width - margin.right])
    .padding(0.1);

const y = d3.scaleLinear()
    .domain([0, d3.max(data, d => d.value)])
    .range([height - margin.bottom, margin.top]);

svg.selectAll('rect')
    .data(data)
    .join('rect')
    .attr('x', d => x(d.name))
    .attr('y', d => y(d.value))
    .attr('width', x.bandwidth())
    .attr('height', d => y(0) - y(d.value))
    .attr('fill', 'steelblue');
```

#### Line Chart
```javascript
const line = d3.line()
    .x(d => x(d.date))
    .y(d => y(d.value));

svg.append('path')
    .datum(data)
    .attr('fill', 'none')
    .attr('stroke', 'steelblue')
    .attr('stroke-width', 2)
    .attr('d', line);
```

#### Pie Chart
```javascript
const pie = d3.pie().value(d => d.value);
const arc = d3.arc().innerRadius(0).outerRadius(radius);

svg.selectAll('path')
    .data(pie(data))
    .join('path')
    .attr('d', arc)
    .attr('fill', (d, i) => d3.schemeCategory10[i]);
```

### Force Layout (Network Graphs)

```javascript
const simulation = d3.forceSimulation(nodes)
    .force('link', d3.forceLink(links).id(d => d.id))
    .force('charge', d3.forceManyBody().strength(-100))
    .force('center', d3.forceCenter(width/2, height/2));

simulation.on('tick', () => {
    // Update positions
    node.attr('cx', d => d.x).attr('cy', d => d.y);
    link.attr('x1', d => d.source.x)
        .attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x)
        .attr('y2', d => d.target.y);
});
```

### Server-Side Rendering

```javascript
// Using jsdom for Node.js
const { JSDOM } = require('jsdom');
const d3 = require('d3');

const dom = new JSDOM('<!DOCTYPE html><body></body>');
const body = d3.select(dom.window.document.body);

const svg = body.append('svg')
    .attr('xmlns', 'http://www.w3.org/2000/svg')
    .attr('width', 800)
    .attr('height', 600);

// ... add elements ...

// Get SVG string
const svgString = body.html();
```
