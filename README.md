# WaRee11
**River Simulation for iPad**

WaRee11 is an iPad-based hydraulic simulation application for modeling 1D river flow using the Saint-Venant equations. The app is designed to help engineers, researchers, and students create river networks, define cross-sections, run simulations, and visualize results directly on iPadOS.

---

# Overview

WaRee11 is a hydraulic modeling application designed for **iPadOS** that allows users to simulate **one-dimensional river flow** using the Saint-Venant equations.

Traditional hydraulic modeling tools typically require powerful desktop computers and complex workflows. WaRee11 aims to simplify this process by providing a **portable and user-friendly modeling environment** that runs directly on an iPad.

The application enables users to:

- Build river networks
- Define channel cross-sections
- Generate rating curves
- Configure simulation parameters
- Run hydraulic simulations
- Visualize water level and discharge results

The project draws inspiration from well-known hydraulic modeling software such as MIKE 11 and HEC-RAS, while focusing on accessibility, portability, and educational usability.

---

# Key Features

## River Network Editor
- Interactive river node creation
- Drag-and-drop node positioning on map
- River branch and connection support
- Schematic river network visualization

## Cross-Section Editor
- Support for multiple cross-section types
- Rectangular channel
- Trapezoidal channel
- Custom terrain profiles

Users can define parameters such as:

- bottom width
- side slope
- depth
- Manning roughness coefficient
- elevation points

A real-time chart preview is provided to visualize cross-section geometry.

## Rating Curve Generation
WaRee11 can automatically generate rating curves (discharge vs water level) for each cross-section.

The calculation is based on the Manning equation:

Q = (1 / n) * A * R^(2/3) * S^(1/2)

Outputs include:

- discharge vs water level table
- rating curve graph
- channel flow capacity estimation

## Hydraulic Solver
The simulation engine solves the **1D Saint-Venant equations** for unsteady open channel flow.

Implemented numerical schemes include:

- MacCormack predictor–corrector scheme
- Lax-Wendroff scheme

These methods allow simulation of water level and discharge variations along the river over time.

## Simulation Runner
The simulation runner loads the required model data and performs time-stepping hydraulic calculations.

Model inputs include:

- river network
- cross-sections
- simulation settings
- boundary conditions

## Results Visualization
Simulation outputs can be visualized through:

- water level vs time graphs
- discharge vs time graphs
- node-based result selection
- tabular data output
---

# Application Workflow

The WaRee11 modeling process follows a structured hydraulic modeling workflow similar to traditional river simulation tools.

Typical workflow:

1. Create a new project
2. Define the river network
3. Input cross-section geometry
4. Configure simulation settings
5. Run the hydraulic simulation
6. Visualize simulation results

This workflow ensures that all required model components are prepared before running the hydraulic solver.
