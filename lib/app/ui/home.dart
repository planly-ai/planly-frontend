import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/controller/fab_controller.dart';
import 'package:planly_ai/app/ui/settings/view/settings.dart';
import 'package:planly_ai/app/ui/statistics/view/statistics.dart';
import 'package:planly_ai/app/ui/tasks/view/all_tasks.dart';
import 'package:planly_ai/app/ui/tasks/widgets/tasks_action.dart';
import 'package:planly_ai/app/ui/todos/view/calendar_todos.dart';
import 'package:planly_ai/app/ui/chatbot/view/chatbot_page.dart';
import 'package:planly_ai/app/ui/todos/widgets/todos_action.dart';
import 'package:planly_ai/app/controller/home_controller.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/navigation_helper.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';
import 'package:planly_ai/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final FabController _fabController = Get.put(
    FabController(),
    permanent: true,
  );

  late final HomeController _homeController = Get.put(
    HomeController(),
    permanent: true,
  );

  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabScaleAnimation;

  static const List<Widget> _pages = [
    AllTasks(),
    CalendarTodos(),
    ChatbotPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeTabIndex();
    _setupFabAnimation();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _setupFabAnimation() {
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: AppConstants.shortAnimation,
    );

    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    ever(_fabController.isVisible, (isVisible) {
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (isVisible) {
            _fabAnimationController.forward();
          } else {
            _fabAnimationController.reverse();
          }
        });
      }
    });

    _fabAnimationController.forward();
  }

  List<String> get _screenKeys => [
    'categories',
    'calendar',
    'chatbot',
    'statistics',
  ];

  void _initializeTabIndex() {
    allScreens = _screenKeys;
    _homeController.tabIndex.value = allScreens.indexOf(
      allScreens.firstWhere(
        (element) => element == settings.defaultScreen,
        orElse: () => allScreens[0],
      ),
    );
  }

  void changeTabIndex(int index) {
    if (_homeController.tabIndex.value != index) {
      _homeController.changeTabIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Obx(() {
      final content = IndexedStack(
        index: _homeController.tabIndex.value,
        children: _pages,
      );

      final body = isMobile
          ? content
          : Row(
              children: [
                _buildNavigationRail(context, isDesktop),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: content),
              ],
            );

      return Scaffold(
        body: body,
        bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    });
  }

  Widget _buildNavigationRail(BuildContext context, bool isExtended) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return NavigationRail(
      selectedIndex: _homeController.tabIndex.value,
      extended: isExtended,
      groupAlignment: -1.0,
      onDestinationSelected: changeTabIndex,
      labelType: isExtended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Padding(
        padding: EdgeInsets.symmetric(vertical: padding * 1.5),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            IconsaxPlusBold.user,
            size: AppConstants.iconSizeLarge,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      destinations: [
        _buildRailDestination(
          IconsaxPlusLinear.folder_2,
          IconsaxPlusBold.folder_2,
          allScreens[0].tr,
        ),
        _buildRailDestination(
          IconsaxPlusLinear.calendar,
          IconsaxPlusBold.calendar,
          allScreens[1].tr,
        ),
        _buildRailDestination(
          IconsaxPlusLinear.message_2,
          IconsaxPlusBold.message_2,
          allScreens[2].tr,
        ),
        _buildRailDestination(
          IconsaxPlusLinear.chart_21,
          IconsaxPlusBold.chart_2,
          allScreens[3].tr,
        ),
        _buildRailDestination(
          IconsaxPlusLinear.setting_2,
          IconsaxPlusBold.setting_2,
          'settings'.tr,
        ),
      ],
    );
  }

  NavigationRailDestination _buildRailDestination(
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    return NavigationRailDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: Text(label),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      onDestinationSelected: changeTabIndex,
      selectedIndex: _homeController.tabIndex.value,
      destinations: _buildNavigationDestinations(),
    );
  }

  List<NavigationDestination> _buildNavigationDestinations() {
    return [
      _buildNavigationDestination(
        icon: IconsaxPlusLinear.folder_2,
        selectedIcon: IconsaxPlusBold.folder_2,
        label: allScreens[0].tr,
      ),
      _buildNavigationDestination(
        icon: IconsaxPlusLinear.calendar,
        selectedIcon: IconsaxPlusBold.calendar,
        label: allScreens[1].tr,
      ),
      _buildNavigationDestination(
        icon: IconsaxPlusLinear.message_2,
        selectedIcon: IconsaxPlusBold.message_2,
        label: allScreens[2].tr,
      ),
      _buildNavigationDestination(
        icon: IconsaxPlusLinear.chart_21,
        selectedIcon: IconsaxPlusBold.chart_2,
        label: allScreens[3].tr,
      ),
      _buildNavigationDestination(
        icon: IconsaxPlusLinear.setting_2,
        selectedIcon: IconsaxPlusBold.setting_2,
        label: 'settings'.tr,
      ),
    ];
  }

  NavigationDestination _buildNavigationDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }

  Widget? _buildFloatingActionButton() {
    const chatbotTabIndex = 2;
    const statisticsTabIndex = 3;
    const settingsTabIndex = 4;

    if (_homeController.tabIndex.value == chatbotTabIndex ||
        _homeController.tabIndex.value == statisticsTabIndex ||
        _homeController.tabIndex.value == settingsTabIndex ||
        !_fabController.isVisible.value) {
      return null;
    }

    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton(
        onPressed: _showCreateSheet,
        child: const Icon(IconsaxPlusLinear.add),
      ),
    );
  }

  void _showCreateSheet() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final widget = _getCreateWidget();

    if (isMobile) {
      NavigationHelper.showModalSheet(context: context, child: widget);
    } else {
      NavigationHelper.showAppDialog(
        context: context,
        child: _buildDialogWrapper(widget),
      );
    }
  }

  Widget _getCreateWidget() {
    return _homeController.tabIndex.value == 0
        ? TasksAction(text: 'create'.tr, edit: false)
        : TodosAction(text: 'create'.tr, edit: false, category: true);
  }

  Widget _buildDialogWrapper(Widget child) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 400,
          maxWidth: AppConstants.maxModalWidth,
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusXXLarge,
            ),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: AppConstants.borderWidthThin,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
