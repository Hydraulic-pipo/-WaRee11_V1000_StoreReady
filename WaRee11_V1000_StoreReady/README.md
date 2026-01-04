#  App Sturcture
#WaRee11_v05
├─ App
│  ├─ AppDelegate.swift
│  ├─ SceneDelegate.swift
│  ├─ Main.storyboard
│  ├─ LaunchScreen.storyboard (ถ้ามี)
│  └─ Assets.xcassets
│
├─ Auth
│  ├─ LoginViewController.swift
│  ├─ RegisterViewController.swift (ถ้ามี)
│  └─ AuthManager.swift
│
├─ Projects
│  ├─ ProjectListViewController.swift
│  ├─ ProjectDetailViewController.swift (อนาคต)
│  ├─ Project.swift
│  └─ ProjectManager.swift
│
├─ RiverNetwork
│  ├─ EditRiverNetworkViewController.swift
│  ├─ RiverNode.swift
│  ├─ RiverBranch.swift (ถ้ามี)
│  └─ RiverNetworkManager.swift (อนาคต)
│
├─ CrossSection
│  ├─ CrossSectionEditorViewController.swift
│  ├─ CrossSectionChartView.swift
│  ├─ CrossSectionModels.swift
│  ├─ CrossSectionStorageManager.swift
│  ├─ RatingCurveViewController.swift
│  └─ RatingCurveResult.swift
│
├─ Simulation
│  ├─ SimulationSettings.swift
│  ├─ SimulationSettingsManager.swift
│  ├─ SimulationSettingsViewController.swift
│  ├─ SimulationRunnerViewController.swift
│  └─ ResultsManager.swift   (หรือจะย้ายไป Results ก็ได้)
│
├─ Solver
│  ├─ SolverManager.swift
│  └─ SolverResult.swift
│
├─ Results
│  ├─ ResultsViewController.swift
│  └─ SolverResultChartView.swift
│
└─ Shared
   ├─ Extensions
   │  └─ (เช่น UIView+AutoLayout.swift ถ้ามีในอนาคต)
   └─ Utilities
      └─ Helpers เล็ก ๆ (เช่น UserDefaults+Coding.swift ฯลฯ)
