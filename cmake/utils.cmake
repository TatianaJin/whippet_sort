# Copyright 2024 Whippet Sort
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

# ~~~
# get all targets under directory (including interface targets)
# _dir is the input directory
# the target list is output to _result
function(_get_all_targets _result _dir)
  message(DEBUG "_get_all_targets DIRECTORY ${_dir}")
  get_property(
    _subdirs
    DIRECTORY "${_dir}"
    PROPERTY SUBDIRECTORIES)
  foreach(_subdir IN LISTS _subdirs)
    _get_all_targets(${_result} "${_subdir}")
  endforeach()

  get_directory_property(_sub_targets DIRECTORY "${_dir}" BUILDSYSTEM_TARGETS)
  set(${_result}
      ${${_result}} ${_sub_targets}
      PARENT_SCOPE)
endfunction()

# ~~~
# get all non-interface targets under directory
# _dir is the input directory
# the target list is output to _result
function(get_all_targets _result _dir)
  _get_all_targets(_tmp_result ${_dir})
  foreach(_target IN LISTS _tmp_result)
    get_target_property(_type ${_target} TYPE)
    if(NOT ${_type} STREQUAL "INTERFACE_LIBRARY")
      set(${_result} ${${_result}} ${_target})
    endif()
  endforeach()
  # set to the scope of the caller function
  set(${_result}
      ${${_result}}
      PARENT_SCOPE)
endfunction()
