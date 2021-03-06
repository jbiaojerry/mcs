/* - mode: c; c-basic-offset: 2; indent-tabs-mode: nil; -*-
 *  vim:expandtab:shiftwidth=2:tabstop=2:smarttab:
 *
 *  Copyright (C) 2010 Brian Aker
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#pragma once

#include <set>

#include <drizzled/plugin/table_function.h>
#include <drizzled/plugin/storage_engine.h>
#include <drizzled/statement/show.h>
#include <drizzled/session.h>
#include <drizzled/current_session.h>
#include <drizzled/message/schema.pb.h>
#include <drizzled/generator.h>

#include <plugin/show_dictionary/show.h>
#include <plugin/show_dictionary/show_columns.h>
#include <plugin/show_dictionary/show_create_schema.h>
#include <plugin/show_dictionary/show_create_table.h>
#include <plugin/show_dictionary/show_indexes.h>
#include <plugin/show_dictionary/show_schemas.h>
#include <plugin/show_dictionary/show_tables.h>
#include <plugin/show_dictionary/show_table_status.h>
#include <plugin/show_dictionary/show_temporary_tables.h>

