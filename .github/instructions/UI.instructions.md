---
applyTo: 'lib/pages/**.dart'
---
# UI Page Instructions

Read this Documentation of Shadcn UI for Flutter ([text](https://sunarya-thito.github.io/shadcn_flutter/llms-full.txt))

When working on UI pages located in the `lib/pages/` directory, please follow these guidelines to ensure consistency and maintainability across the project:
1. **Page Structure**:
   - Each page should be defined in its own Dart file within the `lib/pages/` directory.
   - Use a clear and descriptive name for each file that reflects the purpose of the page (e.g., `home_page.dart`, `settings_page.dart`).
2. **Shadcn UI Widgets**:
    - Always utilize Shadcn UI components / widgets to maintain a consistent look and feel across all pages.
    - Refer to the [Shadcn UI documentation](https://sunarya-thito.github.io/shadcn_flutter/) for available widgets and their usage.
3. **State Management**:
   - Use Flutter's built-in state management.
    - Avoid using third-party state management libraries unless absolutely necessary and approved by the team.
4. **Responsive Design**:
   - Ensure that all pages are responsive and adapt well to different screen sizes and orientations.
   - Test pages on various devices to confirm usability and appearance.
5. **Code Quality**:
   - Follow Dart and Flutter best practices for code quality and readability.
   - Include comments where necessary to explain complex logic or decisions.
6. **Navigation**:
   - Implement navigation using Flutter's Navigator or any approved routing package.
   - Ensure that navigation flows are intuitive and user-friendly.