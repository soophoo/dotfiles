---
name: rn-feature
description: Scaffold a new React Native feature module with 
  screens, navigation, hooks, types, and tests following our 
  architecture.
---

When creating a new feature module:
1. Create the directory structure:
   src/features/<name>/
   ├── screens/        # Screen components
   ├── components/     # Feature-specific components
   ├── hooks/          # Custom hooks for business logic
   ├── types/          # TypeScript types/interfaces
   ├── services/       # API calls (TanStack Query)
   ├── __tests__/      # Colocated tests
   └── index.ts        # Barrel export
2. Every screen gets an Error Boundary wrapper
3. Every API call goes through a custom hook with TanStack Query
4. Navigation types must extend RootStackParamList
5. Run tsc --noEmit after scaffolding to verify types
