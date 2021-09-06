// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:client_data/publisher_api.dart' as api;
import 'package:client_data/page_data.dart';

import '../../audit/models.dart';
import '../../frontend/templates/views/account/activity_log_table.dart';
import '../../package/search_adapter.dart' show SearchResultPage;
import '../../publisher/models.dart' show Publisher, PublisherSummary;
import '../../search/search_form.dart' show SearchForm;
import '../../shared/urls.dart' as urls;

import '_cache.dart';
import 'detail_page.dart';
import 'layout.dart';
import 'listing.dart';
import 'views/publisher/create_page.dart';
import 'views/publisher/header_metadata.dart';
import 'views/publisher/publisher_list.dart';

/// Renders the create publisher page.
String renderCreatePublisherPage() {
  final String content = createPublisherPageNode().toString();
  return renderLayoutPage(
    PageType.standalone,
    content,
    title: 'Create publisher',
    noIndex: true, // no need to index, as the page is only for a logged-in user
  );
}

/// Renders the global publisher list page.
String renderPublisherListPage(List<PublisherSummary> publishers) {
  final content = publisherListNode(publishers: publishers, isGlobal: true);
  return renderLayoutPage(
    PageType.listing,
    content.toString(),
    title: 'Publishers',
    canonicalUrl: '/publishers',
  );
}

/// Renders the search results on the publisher's packages page.
String renderPublisherPackagesPage({
  required Publisher publisher,
  required SearchResultPage searchResultPage,
  required String? messageFromBackend,
  required PageLinks pageLinks,
  required SearchForm searchForm,
  required int totalCount,
  required bool isAdmin,
}) {
  final isSearch = searchForm.hasQuery;
  String title = 'Packages of publisher ${publisher.publisherId}';
  if (isSearch && pageLinks.currentPage! > 1) {
    title += ' | Page ${pageLinks.currentPage}';
  }

  final packageListHtml =
      searchResultPage.hasNoHit ? '' : renderPackageList(searchResultPage);
  final paginationHtml = paginationNode(pageLinks).toString();

  final tabContent = [
    renderListingInfo(
      searchForm: searchForm,
      totalCount: totalCount,
      ownedBy: publisher.publisherId,
      messageFromBackend: messageFromBackend,
    ),
    packageListHtml,
    paginationHtml,
  ].join('\n');

  final tabs = <Tab>[
    Tab.withContent(
      id: 'packages',
      title: 'Packages',
      contentHtml: tabContent,
    ),
    if (isAdmin) _adminLinkTab(publisher.publisherId),
    if (isAdmin) _activityLogLinkTab(publisher.publisherId),
  ];

  final mainContent = renderDetailPage(
    headerHtml: _renderDetailHeader(publisher),
    tabs: tabs,
    infoBoxHtml: null,
  );

  return renderLayoutPage(
    PageType.publisher, mainContent,
    title: title,
    pageData: PageData(
      publisher: PublisherData(
        publisherId: publisher.publisherId,
      ),
    ),
    publisherId: publisher.publisherId,
    searchForm: searchForm,
    canonicalUrl: searchForm.toSearchLink(),
    // index only the first page, if it has packages displayed without search query
    noIndex:
        searchResultPage.hasNoHit || isSearch || pageLinks.currentPage! > 1,
    mainClasses: [wideHeaderDetailPageClassName],
  );
}

/// Renders the `views/publisher/admin_page.mustache` template.
String renderPublisherAdminPage({
  required Publisher publisher,
  required List<api.PublisherMember> members,
}) {
  final String adminContent =
      templateCache.renderTemplate('publisher/admin_page', {
    'publisher_id': publisher.publisherId,
    'description': publisher.description,
    'website_url': publisher.websiteUrl,
    'contact_email': publisher.contactEmail,
    'member_list': members
        .map((m) => {
              'user_id': m.userId,
              'email': m.email,
              'role': m.role,
            })
        .toList(),
  });
  final tabs = <Tab>[
    _packagesLinkTab(publisher.publisherId),
    Tab.withContent(
      id: 'admin',
      title: 'Admin',
      contentHtml: adminContent,
    ),
    _activityLogLinkTab(publisher.publisherId),
  ];

  final content = renderDetailPage(
    headerHtml: _renderDetailHeader(publisher),
    tabs: tabs,
    infoBoxHtml: null,
  );
  return renderLayoutPage(
    PageType.publisher,
    content,
    title: 'Publisher: ${publisher.publisherId}',
    pageData: PageData(
      publisher: PublisherData(
        publisherId: publisher.publisherId,
      ),
    ),
    canonicalUrl: urls.publisherAdminUrl(publisher.publisherId),
    noIndex: true,
    mainClasses: [wideHeaderDetailPageClassName],
  );
}

/// Renders the publisher's activity log page.
String renderPublisherActivityLogPage({
  required Publisher publisher,
  required AuditLogRecordPage activities,
}) {
  final activityLog = activityLogNode(
    baseUrl: urls.publisherActivityLogUrl(publisher.publisherId),
    activities: activities,
    forCategory: 'publisher',
    forEntity: publisher.publisherId,
  );
  final tabs = <Tab>[
    _packagesLinkTab(publisher.publisherId),
    _adminLinkTab(publisher.publisherId),
    Tab.withContent(
      id: 'activity-log',
      title: 'Activity log',
      contentHtml: activityLog.toString(),
    ),
  ];

  final content = renderDetailPage(
    headerHtml: _renderDetailHeader(publisher),
    tabs: tabs,
    infoBoxHtml: null,
  );
  return renderLayoutPage(
    PageType.publisher,
    content,
    title: 'Publisher: ${publisher.publisherId}',
    pageData: PageData(
      publisher: PublisherData(
        publisherId: publisher.publisherId,
      ),
    ),
    canonicalUrl: urls.publisherActivityLogUrl(publisher.publisherId),
    noIndex: true,
    mainClasses: [wideHeaderDetailPageClassName],
  );
}

String _renderDetailHeader(Publisher publisher) {
  return renderDetailHeader(
    title: publisher.publisherId,
    metadataNode: publisherHeaderMetadataNode(publisher),
  );
}

Tab _packagesLinkTab(String publisherId) => Tab.withLink(
      id: 'packages',
      title: 'Packages',
      href: urls.publisherPackagesUrl(publisherId),
    );

Tab _adminLinkTab(String publisherId) => Tab.withLink(
      id: 'admin',
      title: 'Admin',
      href: urls.publisherAdminUrl(publisherId),
    );

Tab _activityLogLinkTab(String publisherId) => Tab.withLink(
      id: 'activity-log',
      title: 'Activity log',
      href: urls.publisherActivityLogUrl(publisherId),
    );
