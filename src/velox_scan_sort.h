// Copyright 2024 Whippet Sort
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.

#pragma once

#include <memory>
#include <string>
#include <unordered_map>

#include <velox/core/PlanNode.h>
#include <velox/parse/PlanNodeIdGenerator.h>

namespace velox {

using ::facebook::velox::core::PlanNodeIdGenerator;

class PlanBuilder {
public:
  ::facebook::velox::core::PlanNodePtr
  tableScan(const std::string &table_name,
            const ::facebook::velox::RowTypePtr &output_type,
            const std::string &hive_connector_id) {
    std::unordered_map<
        std::string,
        std::shared_ptr<::facebook::velox::connector::ColumnHandle>>
        assignments;
    for (uint32_t i = 0; i < output_type->size(); ++i) {
      const auto &name = output_type->nameOf(i);
      const auto &type = output_type->childAt(i);
      assignments.insert(
          {name, std::make_shared<
                     ::facebook::velox::connector::hive::HiveColumnHandle>(
                     name,
                     ::facebook::velox::connector::hive::HiveColumnHandle::
                         ColumnType::kRegular,
                     type, type)});
    }

    auto table_handle =
        std::make_shared<::facebook::velox::connector::hive::HiveTableHandle>(
            hive_connector_id, table_name, true,
            ::facebook::velox::SubfieldFilters(), nullptr, nullptr);
    return std::make_shared<::facebook::velox::core::TableScanNode>(
        nextPlanNodeId(), output_type, table_handle, assignments);
  }

  std::string nextPlanNodeId() {
    // TODO
  }
};

} // namespace velox