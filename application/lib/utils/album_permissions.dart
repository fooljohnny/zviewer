import '../../providers/auth_provider.dart';
import '../../models/album.dart';

/// 图集权限工具类
/// 处理图集相关的权限检查
class AlbumPermissions {
  /// 检查用户是否可以查看图集
  static bool canViewAlbum(Album album, AuthProvider authProvider) {
    // 公开图集所有人都可以查看
    if (album.isPublic) {
      return true;
    }
    
    // 私有图集只有所有者可以查看
    if (authProvider.isAuthenticated && authProvider.user != null) {
      return album.userId == authProvider.user!.id;
    }
    
    return false;
  }

  /// 检查用户是否可以编辑图集
  static bool canEditAlbum(Album album, AuthProvider authProvider) {
    // 未认证用户不能编辑
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      return false;
    }
    
    // 管理员可以编辑所有图集
    if (authProvider.isAdmin) {
      return true;
    }
    
    // 只有图集所有者可以编辑
    return album.userId == authProvider.user!.id;
  }

  /// 检查用户是否可以删除图集
  static bool canDeleteAlbum(Album album, AuthProvider authProvider) {
    // 未认证用户不能删除
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      return false;
    }
    
    // 管理员可以删除所有图集
    if (authProvider.isAdmin) {
      return true;
    }
    
    // 只有图集所有者可以删除
    return album.userId == authProvider.user!.id;
  }

  /// 检查用户是否可以创建图集
  static bool canCreateAlbum(AuthProvider authProvider) {
    // 只有认证用户可以创建图集
    return authProvider.isAuthenticated && authProvider.user != null;
  }

  /// 检查用户是否可以管理图集图片
  static bool canManageAlbumImages(Album album, AuthProvider authProvider) {
    // 未认证用户不能管理
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      return false;
    }
    
    // 管理员可以管理所有图集的图片
    if (authProvider.isAdmin) {
      return true;
    }
    
    // 只有图集所有者可以管理图片
    return album.userId == authProvider.user!.id;
  }

  /// 检查用户是否可以设置图集封面
  static bool canSetAlbumCover(Album album, AuthProvider authProvider) {
    return canManageAlbumImages(album, authProvider);
  }

  /// 检查用户是否可以查看图集统计信息
  static bool canViewAlbumStats(Album album, AuthProvider authProvider) {
    // 管理员可以查看所有图集统计
    if (authProvider.isAdmin) {
      return true;
    }
    
    // 图集所有者可以查看自己的图集统计
    if (authProvider.isAuthenticated && authProvider.user != null) {
      return album.userId == authProvider.user!.id;
    }
    
    return false;
  }

  /// 检查用户是否可以访问管理界面
  static bool canAccessAdminInterface(AuthProvider authProvider) {
    return authProvider.isAuthenticated && authProvider.isAdmin;
  }

  /// 获取图集可见性描述
  static String getVisibilityDescription(Album album) {
    if (album.isPublic) {
      return '公开 - 所有用户都可以查看';
    } else {
      return '私有 - 只有创建者可以查看';
    }
  }

  /// 获取权限错误消息
  static String getPermissionErrorMessage(String action, Album? album) {
    switch (action) {
      case 'view':
        return album?.isPublic == true 
            ? '您没有权限查看此图集'
            : '此图集为私有，只有创建者可以查看';
      case 'edit':
        return '您没有权限编辑此图集';
      case 'delete':
        return '您没有权限删除此图集';
      case 'manage_images':
        return '您没有权限管理此图集的图片';
      case 'set_cover':
        return '您没有权限设置此图集的封面';
      case 'view_stats':
        return '您没有权限查看此图集的统计信息';
      case 'create':
        return '您需要登录才能创建图集';
      case 'admin':
        return '您需要管理员权限才能访问此功能';
      default:
        return '您没有权限执行此操作';
    }
  }

  /// 检查是否需要显示权限提示
  static bool shouldShowPermissionPrompt(String action, Album? album, AuthProvider authProvider) {
    switch (action) {
      case 'view':
        return !canViewAlbum(album!, authProvider);
      case 'edit':
        return !canEditAlbum(album!, authProvider);
      case 'delete':
        return !canDeleteAlbum(album!, authProvider);
      case 'manage_images':
        return !canManageAlbumImages(album!, authProvider);
      case 'set_cover':
        return !canSetAlbumCover(album!, authProvider);
      case 'view_stats':
        return !canViewAlbumStats(album!, authProvider);
      case 'create':
        return !canCreateAlbum(authProvider);
      case 'admin':
        return !canAccessAdminInterface(authProvider);
      default:
        return false;
    }
  }
}

/// 图集权限检查器
/// 用于在UI中检查权限并显示相应的提示
class AlbumPermissionChecker {
  final AuthProvider _authProvider;

  AlbumPermissionChecker(this._authProvider);

  /// 检查权限并返回是否允许
  bool checkPermission(String action, Album? album) {
    switch (action) {
      case 'view':
        return AlbumPermissions.canViewAlbum(album!, _authProvider);
      case 'edit':
        return AlbumPermissions.canEditAlbum(album!, _authProvider);
      case 'delete':
        return AlbumPermissions.canDeleteAlbum(album!, _authProvider);
      case 'manage_images':
        return AlbumPermissions.canManageAlbumImages(album!, _authProvider);
      case 'set_cover':
        return AlbumPermissions.canSetAlbumCover(album!, _authProvider);
      case 'view_stats':
        return AlbumPermissions.canViewAlbumStats(album!, _authProvider);
      case 'create':
        return AlbumPermissions.canCreateAlbum(_authProvider);
      case 'admin':
        return AlbumPermissions.canAccessAdminInterface(_authProvider);
      default:
        return false;
    }
  }

  /// 获取权限错误消息
  String getErrorMessage(String action, Album? album) {
    return AlbumPermissions.getPermissionErrorMessage(action, album);
  }

  /// 检查是否需要显示权限提示
  bool shouldShowPrompt(String action, Album? album) {
    return AlbumPermissions.shouldShowPermissionPrompt(action, album, _authProvider);
  }
}

