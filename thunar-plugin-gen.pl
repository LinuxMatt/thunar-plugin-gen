#!/usr/bin/perl -w
#
# Thunar simple 'Hello World' plugin generator
#
# Copyright (c) 2014 Matt Thirtytwo <matt.59491@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.
#

use strict; use warnings; use v5.10;

sub md {
    my $d = shift;
    -d $d and die "Plugin directory $d already exists.\nI won't overwrite an existing plugin";
    mkdir $d or die "Can't create directory $d: $!";
	say "Directory $d has been created."
}
sub write_file {
    open(FD, ">", $_[0]) or die "Can't open ".$_[0]." for writing: $!";
    print FD $_[1];
    close (FD);
	say "File $_[0] has been written."
}

die "$0 <plugin's short name>\n" unless @ARGV == 1;
my $psn = lc($ARGV[0]);
my $Psn = ucfirst($psn);
my $PSN = uc($psn);
my $tdir = "thunar-$psn";
md $tdir;
my $plugin_c=$tdir."/thunar-$psn-plugin.c";
my $provider_h=$tdir."/thunar-$psn-provider.h";
my $provider_c=$tdir."/thunar-$psn-provider.c";
my $makefile_am=$tdir."/Makefile.am";

my $licence_lgpl=<<"EOT";
/*-
 * Copyright (c) 2014 <your name> <your e-mail>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

EOT

my $plugin_code=<<"EOT";
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <libintl.h>
#include <exo/exo.h>
#include <thunar-${psn}/thunar-${psn}-provider.h>
G_MODULE_EXPORT void thunar_extension_initialize (ThunarxProviderPlugin  *plugin);
G_MODULE_EXPORT void thunar_extension_shutdown   (void);
G_MODULE_EXPORT void thunar_extension_list_types (const GType **types, gint *n_types);
static GType type_list[1];

G_MODULE_EXPORT void thunar_extension_initialize (ThunarxProviderPlugin *plugin)
{
	const gchar *mismatch;
	/* verify that the thunarx versions are compatible */
	mismatch = thunarx_check_version (THUNARX_MAJOR_VERSION, THUNARX_MINOR_VERSION, THUNARX_MICRO_VERSION);
	if (G_UNLIKELY (mismatch != NULL)) {
		g_warning ("Version mismatch: %s", mismatch);
		return;
	}
	g_message ("Initializing Thunar${Psn} extension");

	/* setup i18n support */
	bindtextdomain (GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR);
#ifdef HAVE_BIND_TEXTDOMAIN_CODESET
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
#endif
	/* register the types provided by this plugin */
	${psn}_provider_register_type (plugin);
	/* setup the plugin provider type list */
	type_list[0] = ${PSN}_TYPE_PROVIDER;
}

G_MODULE_EXPORT void thunar_extension_shutdown (void)
{
  g_message ("Shutting down Thunar${Psn} extension");
}

G_MODULE_EXPORT void thunar_extension_list_types (const GType **types, gint *n_types)
{
  *types = type_list;
  *n_types = G_N_ELEMENTS (type_list);
  g_message ("thunar_extension_list_types");
}
EOT

my $provider_h_code=<<"EOT";
#ifndef __${PSN}_PROVIDER_H__
#define __${PSN}_PROVIDER_H__
#include <thunarx/thunarx.h>
G_BEGIN_DECLS;
typedef struct _${Psn}ProviderClass ${Psn}ProviderClass;
typedef struct _${Psn}Provider      ${Psn}Provider;
#define ${PSN}_TYPE_PROVIDER            (${psn}_provider_get_type ())
#define ${PSN}_PROVIDER(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), ${PSN}_TYPE_PROVIDER, ${Psn}Provider))
#define ${PSN}_PROVIDER_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), ${PSN}_TYPE_PROVIDER, ${Psn}ProviderClass))
#define ${PSN}_IS_PROVIDER(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), ${PSN}_TYPE_PROVIDER))
#define ${PSN}_IS_PROVIDER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), ${PSN}_TYPE_PROVIDER))
#define ${PSN}_PROVIDER_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), ${PSN}_TYPE_PROVIDER, ${Psn}ProviderClass))
GType ${psn}_provider_get_type      (void) G_GNUC_CONST;
void  ${psn}_provider_register_type (ThunarxProviderPlugin *plugin);
G_END_DECLS;
#endif /* !__${PSN}_PROVIDER_H__ */
EOT

my $provider_c_code=<<"EOT";
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <gio/gio.h>
#include <gdk/gdkx.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <glib/gi18n.h>
#include <thunar-${psn}/thunar-${psn}-provider.h>

static void   ${psn}_provider_menu_provider_init (ThunarxMenuProviderIface *iface);
static void   ${psn}_provider_finalize           (GObject *object);
static GList* ${psn}_provider_get_file_actions   (ThunarxMenuProvider *menu_provider, GtkWidget *window, GList *files);
static void   ${psn}_action_hello                (GtkAction *action, gpointer user_data);

struct _${Psn}ProviderClass
{
  GObjectClass __parent__;
};
struct _${Psn}Provider
{
  GObject __parent__;
  gchar   *child_watch_path;
  gint    child_watch_id;
};

THUNARX_DEFINE_TYPE_WITH_CODE (${Psn}Provider, ${psn}_provider, G_TYPE_OBJECT,
	THUNARX_IMPLEMENT_INTERFACE (THUNARX_TYPE_MENU_PROVIDER, ${psn}_provider_menu_provider_init));

static void ${psn}_provider_class_init (${Psn}ProviderClass *klass)
{
  GObjectClass *gobject_class;
  gobject_class = G_OBJECT_CLASS (klass);
  gobject_class->finalize = ${psn}_provider_finalize;
  g_message ("${psn}_provider_class_init");
}
static void ${psn}_provider_menu_provider_init (ThunarxMenuProviderIface *iface)
{
  iface->get_file_actions = ${psn}_provider_get_file_actions;
}
static void ${psn}_provider_init (${Psn}Provider *${psn}_provider)
{
  g_message ("${psn}_provider_init");
}
static void ${psn}_provider_finalize (GObject *object)
{
  g_message ("${psn}_provider_finalize");
  G_OBJECT_CLASS (${psn}_provider_parent_class)->finalize (object);
}
static GList* ${psn}_provider_get_file_actions (ThunarxMenuProvider *menu_provider, GtkWidget *window, GList *files)
{
	GList *actions = NULL;
	GFile *location = NULL;
	GtkWidget *action = NULL;

	/* we can only work on a single */
	if (files->next != NULL) {
		return actions;
	}
	/* get the location of the file */
	location = thunarx_file_info_get_location (files->data);
	/* unable to handle non-local files */
	if (G_UNLIKELY (!g_file_has_uri_scheme (location, "file"))) {
		g_object_unref (location);
		return NULL;
	}
	/* release the location */
	g_object_unref (location);

	if (thunarx_file_info_is_directory (files->data)) {
		return actions;
	}
	/* we work on JPEG and PNG files */
	if (thunarx_file_info_has_mime_type (files->data, "image/jpeg")
			||thunarx_file_info_has_mime_type (files->data, "image/png"))
	{
		action = g_object_new (GTK_TYPE_ACTION,	"name", "${Psn}::hello", "icon-name", "background", "label", _("${PSN} plugin says Hello !"), NULL);
		g_signal_connect (action, "activate", G_CALLBACK (${psn}_action_hello), files->data);
		actions = g_list_append (actions, action);
	}
	return actions;
}
static void ${psn}_action_hello (GtkAction *action, gpointer user_data)
{
	g_message("Hello, World !");
}
EOT

my $makefile_am_code=<<"EOT";
AM_CPPFLAGS =					\\
	-I\$(top_builddir)			\\
	-I\$(top_builddir)/plugins	\\
	-I\$(top_srcdir)			\\
	-I\$(top_srcdir)/plugins	\\
	-DG_LOG_DOMAIN=\\"thunar-${psn}\\"		\\
	-DPACKAGE_LOCALE_DIR=\\"\$(localedir)\\"	\\
	\$(PLATFORM_CPPFLAGS)

extensionsdir = \$(libdir)/thunarx-\$(THUNARX_VERSION_API)
extensions_LTLIBRARIES =	\\
	thunar-${psn}.la

thunar_${psn}_la_SOURCES =		\\
	thunar-${psn}-plugin.c		\\
	thunar-${psn}-provider.c	\\
	thunar-${psn}-provider.h

thunar_${psn}_la_CFLAGS =	\\
	\$(EXIF_CFLAGS)			\\
	\$(EXO_CFLAGS)			\\
	\$(GLIB_CFLAGS)			\\
	\$(GTK_CFLAGS)			\\
	\$(LIBX11_CFLAGS)		\\
	\$(PCRE_CFLAGS)			\\
	\$(PLATFORM_CFLAGS)

thunar_${psn}_la_LDFLAGS =	\\
	-avoid-version			\\
	-export-dynamic			\\
	-no-undefined			\\
	-export-symbols-regex "^thunar_extension_(shutdown|initialize|list_types)" \\
	-module					\\
	\$(PLATFORM_LDFLAGS)

thunar_${psn}_la_LIBADD = \\
	\$(top_builddir)/thunarx/libthunarx-\$(THUNARX_VERSION_API).la	\\
	\$(EXIF_LIBS)		\\
	\$(EXO_LIBS)		\\
	\$(GLIB_LIBS)		\\
	\$(GTK_LIBS)		\\
	\$(LIBX11_LIBS)		\\
	\$(PCRE_LIBS)

thunar_${psn}_la_DEPENDENCIES =	\\
	\$(top_builddir)/thunarx/libthunarx-\$(THUNARX_VERSION_API).la

EXTRA_DIST = README

EOT

write_file($plugin_c,$licence_lgpl.$plugin_code);
write_file($provider_h,$licence_lgpl.$provider_h_code);
write_file($provider_c,$licence_lgpl.$provider_c_code);
write_file($makefile_am,$makefile_am_code);

