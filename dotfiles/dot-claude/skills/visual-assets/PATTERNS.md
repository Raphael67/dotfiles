# Patterns & Templates

Ready-to-use templates for common diagram and animation patterns.

---

## Software Architecture

### API Gateway Pattern (Mermaid)

```mermaid
flowchart TB
    subgraph Clients
        web[Web App]
        mobile[Mobile App]
        cli[CLI]
    end

    gateway[API Gateway]

    subgraph Services
        auth[Auth Service]
        users[User Service]
        orders[Order Service]
        notify[Notification Service]
    end

    subgraph Data
        userdb[(User DB)]
        orderdb[(Order DB)]
        cache[(Redis Cache)]
    end

    web --> gateway
    mobile --> gateway
    cli --> gateway

    gateway --> auth
    gateway --> users
    gateway --> orders
    gateway --> notify

    users --> userdb
    users --> cache
    orders --> orderdb
    orders --> cache
    notify --> cache
```

### Microservices Topology (D2)

```d2
direction: right

clients: {
    web: Web App
    mobile: Mobile App
}

gateway: API Gateway {
    style.fill: "#4A90D9"
}

services: {
    auth: Auth {
        icon: https://icons.terrastruct.com/essentials/lock.svg
    }
    users: Users
    orders: Orders
    payments: Payments
    notifications: Notifications
}

data: {
    postgres: PostgreSQL {
        shape: cylinder
    }
    redis: Redis {
        shape: cylinder
    }
    kafka: Kafka {
        shape: queue
    }
}

clients.web -> gateway
clients.mobile -> gateway

gateway -> services.auth
gateway -> services.users
gateway -> services.orders

services.users -> data.postgres
services.orders -> data.postgres
services.orders -> data.kafka
services.payments -> data.kafka
services.notifications <- data.kafka
services.* -> data.redis: cache
```

### C4 Context Diagram (Mermaid)

```mermaid
C4Context
    title System Context - E-Commerce Platform

    Person(customer, "Customer", "Online shopper")
    Person(admin, "Admin", "Platform administrator")

    System(ecommerce, "E-Commerce Platform", "Main application")

    System_Ext(payment, "Payment Gateway", "Stripe/PayPal")
    System_Ext(shipping, "Shipping Provider", "FedEx/UPS API")
    System_Ext(email, "Email Service", "SendGrid")

    Rel(customer, ecommerce, "Browses, purchases")
    Rel(admin, ecommerce, "Manages products, orders")
    Rel(ecommerce, payment, "Processes payments")
    Rel(ecommerce, shipping, "Creates shipments")
    Rel(ecommerce, email, "Sends notifications")
```

### Event-Driven Architecture (PlantUML)

```plantuml
@startuml
!theme cerulean

title Event-Driven Architecture

rectangle "Producers" {
    [Order Service] as OS
    [User Service] as US
    [Payment Service] as PS
}

queue "Event Bus (Kafka)" as EB

rectangle "Consumers" {
    [Notification Service] as NS
    [Analytics Service] as AS
    [Search Indexer] as SI
}

database "Event Store" as ES

OS --> EB : OrderCreated\nOrderShipped
US --> EB : UserRegistered\nUserUpdated
PS --> EB : PaymentCompleted\nPaymentFailed

EB --> NS : *
EB --> AS : *
EB --> SI : UserUpdated\nOrderCreated

EB --> ES : All events
@enduml
```

---

## Data & Database

### Relational ERD (Mermaid)

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    USER ||--o{ ADDRESS : has
    USER ||--o{ REVIEW : writes

    ORDER ||--|{ ORDER_ITEM : contains
    ORDER ||--|| PAYMENT : has
    ORDER }|--|| ADDRESS : ships_to

    PRODUCT ||--o{ ORDER_ITEM : "ordered in"
    PRODUCT ||--o{ REVIEW : receives
    PRODUCT }|--|| CATEGORY : belongs_to

    USER {
        uuid id PK
        string email UK
        string password_hash
        string name
        timestamp created_at
    }

    ORDER {
        uuid id PK
        uuid user_id FK
        uuid address_id FK
        decimal total
        string status
        timestamp created_at
    }

    PRODUCT {
        uuid id PK
        uuid category_id FK
        string name
        text description
        decimal price
        int stock
    }

    ORDER_ITEM {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        int quantity
        decimal unit_price
    }
```

### SQL Tables (D2)

```d2
users: {
    shape: sql_table
    id: uuid {constraint: primary_key}
    email: varchar(255) {constraint: unique}
    name: varchar(100)
    created_at: timestamp
}

orders: {
    shape: sql_table
    id: uuid {constraint: primary_key}
    user_id: uuid {constraint: foreign_key}
    total: decimal(10,2)
    status: varchar(20)
    created_at: timestamp
}

products: {
    shape: sql_table
    id: uuid {constraint: primary_key}
    name: varchar(200)
    price: decimal(10,2)
    stock: int
}

order_items: {
    shape: sql_table
    id: uuid {constraint: primary_key}
    order_id: uuid {constraint: foreign_key}
    product_id: uuid {constraint: foreign_key}
    quantity: int
    unit_price: decimal(10,2)
}

users.id <-> orders.user_id
orders.id <-> order_items.order_id
products.id <-> order_items.product_id
```

### Data Pipeline Flow (Mermaid)

```mermaid
flowchart LR
    subgraph Sources
        api[REST API]
        db[(Production DB)]
        logs[Log Files]
        events[Event Stream]
    end

    subgraph Ingestion
        kafka[Kafka]
        kinesis[Kinesis]
    end

    subgraph Processing
        spark[Spark]
        flink[Flink]
    end

    subgraph Storage
        s3[(S3 Data Lake)]
        warehouse[(Data Warehouse)]
        elastic[(Elasticsearch)]
    end

    subgraph Analytics
        bi[BI Dashboard]
        ml[ML Models]
        alerts[Alerting]
    end

    api --> kafka
    db --> kafka
    logs --> kinesis
    events --> kafka

    kafka --> spark
    kinesis --> flink

    spark --> s3
    spark --> warehouse
    flink --> elastic

    s3 --> ml
    warehouse --> bi
    elastic --> alerts
```

---

## Process & Workflow

### Git Branching Strategy (Mermaid)

```mermaid
gitGraph
    commit id: "Initial"
    branch develop
    checkout develop
    commit id: "Setup"

    branch feature/auth
    checkout feature/auth
    commit id: "Add login"
    commit id: "Add OAuth"
    checkout develop
    merge feature/auth

    branch feature/dashboard
    checkout feature/dashboard
    commit id: "Dashboard UI"
    checkout develop

    branch release/1.0
    checkout release/1.0
    commit id: "Version bump"

    checkout main
    merge release/1.0 tag: "v1.0.0"

    checkout develop
    merge release/1.0

    checkout feature/dashboard
    commit id: "Charts"
    checkout develop
    merge feature/dashboard

    branch hotfix/security
    checkout hotfix/security
    commit id: "Fix XSS"
    checkout main
    merge hotfix/security tag: "v1.0.1"
    checkout develop
    merge hotfix/security
```

### CI/CD Pipeline (Mermaid)

```mermaid
flowchart LR
    subgraph Development
        code[Code Push]
        pr[Pull Request]
    end

    subgraph CI["CI Pipeline"]
        lint[Lint]
        test[Unit Tests]
        build[Build]
        scan[Security Scan]
    end

    subgraph CD["CD Pipeline"]
        staging[Deploy Staging]
        e2e[E2E Tests]
        approval{Approval}
        prod[Deploy Production]
    end

    subgraph Monitoring
        metrics[Metrics]
        logs[Logs]
        alerts[Alerts]
    end

    code --> pr --> lint
    lint --> test --> build --> scan
    scan --> staging --> e2e --> approval
    approval -->|Approved| prod
    approval -->|Rejected| code
    prod --> metrics & logs & alerts
```

### State Machine (Mermaid)

```mermaid
stateDiagram-v2
    [*] --> Draft

    Draft --> Pending: Submit
    Draft --> Cancelled: Cancel

    Pending --> Approved: Approve
    Pending --> Rejected: Reject
    Pending --> Draft: Request Changes

    Approved --> Processing: Start
    Rejected --> Draft: Revise
    Rejected --> Cancelled: Abandon

    Processing --> Completed: Finish
    Processing --> Failed: Error

    Failed --> Processing: Retry
    Failed --> Cancelled: Abandon

    Completed --> [*]
    Cancelled --> [*]

    state Processing {
        [*] --> Step1
        Step1 --> Step2
        Step2 --> Step3
        Step3 --> [*]
    }
```

### Decision Flowchart (Mermaid)

```mermaid
flowchart TD
    start([Start]) --> input[/Receive Request/]
    input --> auth{Authenticated?}

    auth -->|No| login[Redirect to Login]
    login --> auth

    auth -->|Yes| perm{Has Permission?}

    perm -->|No| deny[Access Denied]
    deny --> stop1([End])

    perm -->|Yes| validate{Valid Input?}

    validate -->|No| error[Show Validation Error]
    error --> input

    validate -->|Yes| process[Process Request]
    process --> db[(Save to Database)]
    db --> notify[Send Notification]
    notify --> success[Return Success]
    success --> stop2([End])
```

### User Journey (Mermaid)

```mermaid
journey
    title User Purchase Journey

    section Discovery
        Visit homepage: 5: User
        Search for product: 4: User
        View search results: 4: User, System

    section Evaluation
        View product details: 5: User
        Read reviews: 4: User
        Compare products: 3: User

    section Purchase
        Add to cart: 5: User
        View cart: 5: User
        Enter shipping info: 3: User
        Enter payment: 2: User
        Confirm order: 4: User, System

    section Post-Purchase
        Receive confirmation: 5: System
        Track shipment: 4: User, System
        Receive delivery: 5: User
        Write review: 3: User
```

### Gantt Project Timeline (Mermaid)

```mermaid
gantt
    title Project Timeline
    dateFormat YYYY-MM-DD
    excludes weekends

    section Planning
    Requirements gathering     :a1, 2024-01-01, 5d
    Technical design          :a2, after a1, 5d
    Architecture review       :milestone, after a2, 0d

    section Development
    Backend API              :crit, b1, 2024-01-15, 15d
    Frontend UI              :b2, 2024-01-15, 12d
    Database setup           :b3, 2024-01-15, 5d
    Integration              :b4, after b1, 5d

    section Testing
    Unit testing             :c1, after b2, 5d
    Integration testing      :c2, after b4, 5d
    UAT                      :c3, after c2, 5d
    Bug fixes                :c4, after c3, 3d

    section Deployment
    Staging deployment       :d1, after c4, 2d
    Production deployment    :milestone, crit, after d1, 0d
```

---

## Animation Patterns

### Animated Flowchart (Manim)

```python
from manim import *

class AnimatedFlowchart(Scene):
    def construct(self):
        # Create nodes
        start = Circle(radius=0.3, color=GREEN).shift(UP*2)
        start_text = Text("Start", font_size=20).move_to(start)

        process1 = Rectangle(width=2, height=0.8, color=BLUE)
        process1_text = Text("Process A", font_size=18).move_to(process1)

        decision = Polygon(
            UP*0.5, RIGHT*0.8, DOWN*0.5, LEFT*0.8,
            color=YELLOW
        ).shift(DOWN*1.5)
        decision_text = Text("?", font_size=24).move_to(decision)

        end = Circle(radius=0.3, color=RED).shift(DOWN*3)
        end_text = Text("End", font_size=20).move_to(end)

        # Create arrows
        arrow1 = Arrow(start.get_bottom(), process1.get_top(), buff=0.1)
        arrow2 = Arrow(process1.get_bottom(), decision.get_top(), buff=0.1)
        arrow3 = Arrow(decision.get_bottom(), end.get_top(), buff=0.1)

        # Animate
        self.play(Create(start), Write(start_text))
        self.play(GrowArrow(arrow1))
        self.play(Create(process1), Write(process1_text))
        self.play(GrowArrow(arrow2))
        self.play(Create(decision), Write(decision_text))
        self.play(GrowArrow(arrow3))
        self.play(Create(end), Write(end_text))
        self.wait()
```

### Data Visualization (Manim)

```python
from manim import *

class BarChartAnimation(Scene):
    def construct(self):
        chart = BarChart(
            values=[3, 5, 2, 8, 4],
            bar_names=["A", "B", "C", "D", "E"],
            y_range=[0, 10, 2],
            y_length=5,
            x_length=8,
            bar_colors=[BLUE, GREEN, RED, YELLOW, PURPLE]
        )

        self.play(Create(chart), run_time=2)
        self.wait()

        # Animate value change
        self.play(
            chart.animate.change_bar_values([5, 3, 7, 4, 6]),
            run_time=1.5
        )
        self.wait()
```

### Particle System (p5.js)

```javascript
let particles = [];

function setup() {
    createCanvas(800, 600);
}

function draw() {
    background(20, 20, 30);

    // Add new particles at mouse
    if (mouseIsPressed) {
        for (let i = 0; i < 3; i++) {
            particles.push(new Particle(mouseX, mouseY));
        }
    }

    // Update and draw particles
    for (let i = particles.length - 1; i >= 0; i--) {
        particles[i].update();
        particles[i].draw();

        if (particles[i].isDead()) {
            particles.splice(i, 1);
        }
    }
}

class Particle {
    constructor(x, y) {
        this.pos = createVector(x, y);
        this.vel = createVector(random(-2, 2), random(-5, -2));
        this.acc = createVector(0, 0.1);
        this.lifespan = 255;
        this.size = random(5, 15);
        this.color = color(random(100, 255), random(50, 150), random(200, 255));
    }

    update() {
        this.vel.add(this.acc);
        this.pos.add(this.vel);
        this.lifespan -= 3;
    }

    draw() {
        noStroke();
        this.color.setAlpha(this.lifespan);
        fill(this.color);
        circle(this.pos.x, this.pos.y, this.size);
    }

    isDead() {
        return this.lifespan <= 0;
    }
}
```

### Animated Bar Chart (D3.js)

```javascript
const data = [
    { name: 'A', value: 30 },
    { name: 'B', value: 50 },
    { name: 'C', value: 20 },
    { name: 'D', value: 80 },
    { name: 'E', value: 45 }
];

const width = 600, height = 400;
const margin = { top: 20, right: 20, bottom: 30, left: 40 };

const x = d3.scaleBand()
    .domain(data.map(d => d.name))
    .range([margin.left, width - margin.right])
    .padding(0.2);

const y = d3.scaleLinear()
    .domain([0, d3.max(data, d => d.value)])
    .range([height - margin.bottom, margin.top]);

const svg = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height);

// Animated bars
svg.selectAll('rect')
    .data(data)
    .join('rect')
    .attr('x', d => x(d.name))
    .attr('width', x.bandwidth())
    .attr('y', height - margin.bottom)
    .attr('height', 0)
    .attr('fill', 'steelblue')
    .transition()
    .duration(800)
    .delay((d, i) => i * 100)
    .attr('y', d => y(d.value))
    .attr('height', d => y(0) - y(d.value));

// Axes
svg.append('g')
    .attr('transform', `translate(0,${height - margin.bottom})`)
    .call(d3.axisBottom(x));

svg.append('g')
    .attr('transform', `translate(${margin.left},0)`)
    .call(d3.axisLeft(y));
```
