const std = @import("std");

pub fn LinkedList(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        head: ?*Node = null,
        tail: ?*Node = null,

        // ------------------------------------------------------------------------------ \\
        //  Errors                                                                        \\
        // ------------------------------------------------------------------------------ \\
        pub const LinkedListError = error{
            OutOfBoundError,
            InvalidIterationBoundaries,
        };

        // ------------------------------------------------------------------------------ \\
        //  Enums                                                                         \\
        // ------------------------------------------------------------------------------ \\
        const LinkedListIteratorStart = enum {
            head,
            tail,
        };

        // ------------------------------------------------------------------------------ \\
        //  Generic structs                                                               \\
        // ------------------------------------------------------------------------------ \\

        /// Indexed iterator item. Contains value of `E` type and index of this element in list.
        fn IndexedItem(comptime E: type) type {
            return struct {
                item: E,
                index: usize,
            };
        }

        // ------------------------------------------------------------------------------ \\
        //  Structs                                                                       \\
        // ------------------------------------------------------------------------------ \\

        /// List node element. Contains value and pointers to next and previous nodes.
        ///
        /// If node doesn't references to another one nodes than `next` and(or) `previous` fields have to be `null`.
        const Node = struct {
            value: T,
            next: ?*Node = null,
            previous: ?*Node = null,
        };

        /// List iteration boundaries. Contains information to about list iteration limitations.
        ///
        /// If no borders required `start_at_index` and(or) `stop_at_index` fields have to be `null`.
        const IterationBoundaries = struct {
            start_at_index: ?usize = null,
            stop_at_index: ?usize = null,
        };

        /// List nodes iterator. Contains node and methods to walk through the list nodes beginning from the contained node.
        ///
        /// Returns next node pointer using `.next()` if it's exists else returns `null`, changes contained node.
        ///
        /// Returns previous node pointer using `.previous()` if it's exists else returns `null`, changes contained node.
        const NodesIterator = struct {
            current_node: ?*Node,
            current_index: usize,

            /// Returns pointer to list node and goes to the next one.
            ///
            /// If list doesn't have node returns `null`.
            pub fn next(self: *@This()) ?*Node {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.next;

                    defer self.current_index +|= 1;
                    return item;
                }
                return null;
            }

            /// Returns container containing pointer to list node and it's index. Goes to the next one.
            ///
            /// If list doesn't have node returns `null`.
            pub fn nextWithIndex(self: *@This()) ?IndexedItem(*T) {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.next;

                    defer self.current_index +|= 1;
                    return .{ .item = item, .index = self.current_index };
                }
                return null;
            }

            /// Returns pointer to list node and goes to the previous one.
            ///
            /// If list doesn't have node returns `null`.
            pub fn previous(self: *@This()) ?*Node {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.previous;

                    defer self.current_index -|= 1;
                    return item;
                }
                return null;
            }

            /// Returns container containing pointer to list node and it's index. Goes to the previous one.
            ///
            /// If list doesn't have node returns `null`.
            pub fn previousWithIndex(self: *@This()) ?IndexedItem(*T) {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.previous;

                    defer self.current_index -|= 1;
                    return .{ .item = item, .index = self.current_index };
                }
                return null;
            }
        };

        /// List elements iterator. Contains node and methods to walk through the list elements beginning from the contained node.
        ///
        /// Returns next element pointer node using `.next()` if it's exists else returns `null`, changes contained node.
        ///
        /// Returns previous element pointer node using `.previous()` if it's exists else returns `null`, changes contained node.
        pub const ElementsIterator = struct {
            current_node: ?*Node,
            current_index: usize,

            /// Returns pointer to list element and goes to the next one.
            ///
            /// If list doesn't have element returns `null`.
            pub fn next(self: *@This()) ?*T {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.next;

                    defer self.current_index +|= 1;
                    return &item.value;
                }
                return null;
            }

            /// Returns container containing pointer to list element and it's index. Goes to the next one.
            ///
            /// If list doesn't have element returns `null`.
            pub fn nextWithIndex(self: *@This()) ?IndexedItem(*T) {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.next;

                    defer self.current_index +|= 1;
                    return .{ .item = &item.value, .index = self.current_index };
                }
                return null;
            }

            /// Returns pointer to list element and goes to the previous one.
            ///
            /// If list doesn't have element returns `null`.
            pub fn previous(self: *@This()) ?*T {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.previous;

                    defer self.current_index -|= 1;
                    return &item.value;
                }
                return null;
            }

            /// Returns container containing pointer to list element and it's index. Goes to the previous one.
            ///
            /// If list doesn't have element returns `null`.
            pub fn previousWithIndex(self: *@This()) ?IndexedItem(*T) {
                if (self.current_node) |item| {
                    self.current_node = self.current_node.?.previous;

                    defer self.current_index -|= 1;
                    return .{ .item = &item.value, .index = self.current_index };
                }
                return null;
            }
        };

        // ------------------------------------------------------------------------------ \\
        //  Methods                                                                       \\
        // ------------------------------------------------------------------------------ \\

        /// Initializes new linked list.
        ///
        /// List have to be deinited after finish operating with it using `.clear()` method to free the memory.
        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{ .allocator = allocator };
        }

        /// Initializes new linked list and fill it with slice values.
        ///
        /// List have to be deinited after finish operating with it using `.clear()` method to free the memory.
        pub fn initWithSlice(allocator: std.mem.Allocator, slice: []const T) !@This() {
            var linked_list: @This() = .{ .allocator = allocator };
            errdefer linked_list.clear();

            for (slice) |item| {
                try linked_list.addToTail(item);
            }

            return linked_list;
        }

        /// Deallocates all of the list elements.
        ///
        /// This method have to be called after finish operating with list to free the memory.
        pub fn clear(self: *@This()) void {
            for (0..self.size()) |_| {
                self.deleteFromTail();
            }
        }

        /// Returns iterator to iterate list nodes using`.next()` and `.previous()` methods.
        ///
        /// If iterator reaches last value returns `null`.
        pub fn nodesIterator(self: @This(), start_node: LinkedListIteratorStart) NodesIterator {
            return switch (start_node) {
                .head => NodesIterator{ .current_node = self.head, .current_index = 0 },
                .tail => NodesIterator{ .current_node = self.tail, .current_index = self.size() - 1 },
            };
        }

        /// Returns iterator to iterate list elements pointers using`.next()` and `.previous()` methods.
        ///
        /// If iterator reaches last value returns `null`.
        pub fn elementsIterator(self: @This(), start_node: LinkedListIteratorStart) ElementsIterator {
            return switch (start_node) {
                .head => ElementsIterator{ .current_node = self.head, .current_index = 0 },
                .tail => ElementsIterator{ .current_node = self.tail, .current_index = self.size() - 1 },
            };
        }

        /// Adds new value to the tail of the list.
        pub fn addToTail(self: *@This(), value: T) !void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .value = value };

            if (self.tail == null) {
                self.tail = new_node;
                self.head = new_node;
                return;
            }

            self.tail.?.next = new_node;
            new_node.previous = self.tail;

            self.tail = new_node;
        }

        /// Adds new value to the head of the list.
        pub fn addToHead(self: *@This(), value: T) !void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .value = value };

            if (self.head == null) {
                self.head = new_node;
                self.tail = new_node;
                return;
            }

            new_node.next = self.head;
            self.head.?.previous = new_node;

            self.head = new_node;
        }

        // Deletes value from the tail of the list.
        pub fn deleteFromTail(self: *@This()) void {
            if (self.isEmpty()) {
                return;
            }

            if (self.tail.?.previous == null) {
                self.allocator.destroy(self.tail.?);
                self.head = null;
                self.tail = null;
            } else {
                var new_last_node = self.tail.?.previous.?;
                new_last_node.next = null;

                self.allocator.destroy(self.tail.?);
                self.tail = new_last_node;
            }
        }

        // Deletes value from the head of the list.
        pub fn deleteFromHead(self: *@This()) void {
            if (self.isEmpty()) {
                return;
            }

            if (self.head.?.next == null) {
                self.allocator.destroy(self.head.?);
                self.head = null;
                self.tail = null;
            } else {
                var new_first_node = self.head.?.next.?;
                new_first_node.previous = null;

                self.allocator.destroy(self.head.?);
                self.head = new_first_node;
            }
        }

        // Gets list value located at given index.
        pub fn get(self: @This(), node_index: usize) !*T {
            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (node_index == counter) return item;
                counter += 1;
            }

            return LinkedListError.OutOfBoundError;
        }

        /// Sets value located at given index.
        pub fn set(self: *@This(), node_index: usize, value: T) !void {
            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (node_index == counter) {
                    item.* = value;
                    return;
                }
                counter += 1;
            }

            return LinkedListError.OutOfBoundError;
        }

        /// Inserts value at given index.
        pub fn insert(self: *@This(), node_index: usize, value: T) !void {
            var counter: usize = 0;
            var selected_node: ?*Node = null;

            var nodes_iterator = self.nodesIterator(.head);
            while (nodes_iterator.next()) |item| {
                if (node_index == counter) {
                    selected_node = item;
                    break;
                }
                counter += 1;
            }

            if (selected_node == null) {
                return LinkedListError.OutOfBoundError;
            }

            if (selected_node == self.head) {
                try self.addToHead(value);
                return;
            }

            if (selected_node == self.tail) {
                try self.addToTail(value);
                return;
            }

            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .value = value, .next = selected_node, .previous = selected_node.?.previous };

            selected_node.?.previous.?.next = new_node;
            selected_node.?.previous = new_node;
        }

        /// Inserts slice values at given index.
        pub fn insertSlice(self: *@This(), node_index: usize, slice: []const T) !void {
            const reversed_slice = try self.allocator.alloc(T, slice.len);
            defer self.allocator.free(reversed_slice);

            @memcpy(reversed_slice, slice);
            std.mem.reverse(T, reversed_slice);

            for (reversed_slice) |item| {
                try self.insert(node_index, item);
            }
        }

        /// Deletes value located at given index.
        pub fn delete(self: *@This(), node_index: usize) !void {
            var counter: usize = 0;
            var selected_node: ?*Node = null;

            var nodes_iterator = self.nodesIterator(.head);
            while (nodes_iterator.next()) |item| {
                if (node_index == counter) {
                    selected_node = item;
                    break;
                }
                counter += 1;
            }

            if (selected_node == null) {
                return LinkedListError.OutOfBoundError;
            }

            if (selected_node == self.head) {
                self.deleteFromHead();
                return;
            }

            if (selected_node == self.tail) {
                self.deleteFromTail();
                return;
            }

            selected_node.?.previous.?.next = selected_node.?.next;
            selected_node.?.next.?.previous = selected_node.?.previous;

            self.allocator.destroy(selected_node.?);
        }

        /// Deletes value located at given index and return it's copy.
        pub fn pop(self: *@This(), node_index: usize) !T {
            var counter: usize = 0;
            var selected_node: ?*Node = null;

            var nodes_iterator = self.nodesIterator(.head);
            while (nodes_iterator.next()) |item| {
                if (node_index == counter) {
                    selected_node = item;
                    break;
                }
                counter += 1;
            }

            if (selected_node == null) {
                return LinkedListError.OutOfBoundError;
            }

            const result_value = selected_node.?.value;

            if (selected_node == self.head) {
                self.deleteFromHead();
                return result_value;
            }

            if (selected_node == self.tail) {
                self.deleteFromTail();
                return result_value;
            }

            selected_node.?.previous.?.next = selected_node.?.next;
            selected_node.?.next.?.previous = selected_node.?.previous;

            self.allocator.destroy(selected_node.?);

            return result_value;
        }

        /// Finds index of given value in list.
        ///
        /// If value index was not found returns `null`.
        pub fn index(self: @This(), value: T, search_boundaries: IterationBoundaries) !?usize {
            if (self.isEmpty()) {
                return null;
            }

            const range_start_index = search_boundaries.start_at_index orelse 0;
            const range_stop_index = search_boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index and item.* == value) return counter;
                counter += 1;
            }

            return null;
        }

        /// Finds all of the indexes of given value in list.
        ///
        /// If value indexes were not found returns `null`.
        ///
        /// Result list have to be freed using `.clear()` method after finish operating with it to free the memory.
        pub fn indexAll(self: @This(), value: T, search_boundaries: IterationBoundaries) !?LinkedList(usize) {
            if (self.isEmpty()) {
                return null;
            }

            const range_start_index = search_boundaries.start_at_index orelse 0;
            const range_stop_index = search_boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var result_list = LinkedList(usize).init(self.allocator);
            errdefer result_list.clear();

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index and item.* == value) try result_list.addToTail(counter);
                counter += 1;
            }

            if (result_list.isEmpty()) {
                return null;
            }

            return result_list;
        }

        /// Finds value equals given value.
        ///
        /// If value was not found returns `null`.
        pub fn find(self: @This(), value: T, search_boundaries: IterationBoundaries) !?*T {
            if (self.isEmpty()) {
                return null;
            }

            const range_start_index = search_boundaries.start_at_index orelse 0;
            const range_stop_index = search_boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index and item.* == value) return item;
                counter += 1;
            }

            return null;
        }

        /// Finds all of the values equals given value.
        ///
        /// If values were not found returns `null`.
        ///
        /// Result list have to be freed using `.clear()` method after finish operating with it to free the memory.
        pub fn findAll(self: @This(), value: T, search_boundaries: IterationBoundaries) !?LinkedList(*T) {
            if (self.isEmpty()) {
                return null;
            }

            const range_start_index = search_boundaries.start_at_index orelse 0;
            const range_stop_index = search_boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var result_list = LinkedList(*T).init(self.allocator);
            errdefer result_list.clear();

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index and item.* == value) try result_list.addToTail(item);
                counter += 1;
            }

            if (result_list.isEmpty()) {
                return null;
            }

            return result_list;
        }

        /// Finds and replaces value to new value.
        ///
        /// Retruns `true` if value was found and replaced else `false`.
        pub fn replace(self: *@This(), value_to_replace: T, new_value: T, search_boundaries: IterationBoundaries) !bool {
            if (self.isEmpty()) {
                return false;
            }

            const range_start_index = search_boundaries.start_at_index orelse 0;
            const range_stop_index = search_boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index and item.* == value_to_replace) {
                    item.* = new_value;
                    return true;
                }
                counter += 1;
            }

            return false;
        }

        /// Finds and replaces all of the values to new value.
        ///
        /// Retruns amount of replaced values.
        pub fn replaceAll(self: *@This(), value_to_reaplce: T, new_value: T, search_boundaries: IterationBoundaries) !usize {
            if (self.isEmpty()) {
                return 0;
            }

            const range_start_index = search_boundaries.start_at_index orelse 0;
            const range_stop_index = search_boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;
            var replaces_counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index and item.* == value_to_reaplce) {
                    item.* = new_value;
                    replaces_counter += 1;
                }
                counter += 1;
            }

            return replaces_counter;
        }

        /// Counts amount of elements with given value in list.
        pub fn count(self: @This(), value: T) usize {
            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (item.* == value) counter += 1;
            }

            return counter;
        }

        /// Checks if given value contains in list.
        pub fn contains(self: @This(), value: T) bool {
            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (item.* == value) return true;
            }

            return false;
        }

        /// Checks if given value contains in list at least `n` times.
        pub fn containsAtLeast(self: @This(), value: T, times: usize) bool {
            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (item.* == value) counter += 1;
            }

            if (counter >= times) return true else false;
        }

        /// Retrives list size.
        pub fn size(self: @This()) usize {
            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |_| {
                counter += 1;
            }

            return counter;
        }

        /// Checks if list is empty.
        pub fn isEmpty(self: @This()) bool {
            if (self.head != null) return false else return true;
        }

        /// Creates deep copy of the list.
        ///
        /// New list have to be deinited after finish operating with it using `.clear()` method to free the memory.
        pub fn copy(self: @This(), allocator: std.mem.Allocator) !LinkedList(T) {
            var new_list = LinkedList(T).init(allocator);

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                try new_list.addToTail(item.*);
            }

            return new_list;
        }

        /// Reverses all of the list values.
        pub fn reverse(self: *@This()) !void {
            var new_list = LinkedList(T).init(self.allocator);

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                try new_list.addToHead(item.*);
            }

            self.clear();
            self.* = new_list;
        }

        /// Swaps elements at given indexes.
        pub fn swapElements(self: *@This(), first_element_index: usize, seconds_element_index: usize) !void {
            var counter: usize = 0;

            var first_element: ?*T = null;
            var second_element: ?*T = null;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (counter == first_element_index) {
                    first_element = item;
                }
                if (counter == seconds_element_index) {
                    second_element = item;
                }
                counter += 1;
            }

            if (first_element == null or second_element == null) {
                return LinkedListError.OutOfBoundError;
            }

            const temp = first_element.?.*;
            first_element.?.* = second_element.?.*;
            second_element.?.* = temp;
        }

        /// Calls given function for list elements.
        pub fn mapElements(self: *@This(), map_fn: *const fn (element: *T, index: usize) void, boundaries: IterationBoundaries) !void {
            const range_start_index = boundaries.start_at_index orelse 0;
            const range_stop_index = boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index) map_fn(item, counter);
                counter += 1;
            }
        }

        /// Calls given function for list nodes.
        pub fn mapNodes(self: *@This(), map_fn: *const fn (node: *Node, index: usize) void, boundaries: IterationBoundaries) !void {
            const range_start_index = boundaries.start_at_index orelse 0;
            const range_stop_index = boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var nodes_iterator = self.nodesIterator(.head);
            while (nodes_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index) map_fn(item, counter);
                counter += 1;
            }
        }

        /// Gathers list elements that successfully pass filter function.
        ///
        /// If no one element passed filter functions returns `null`.
        ///
        /// Result list have to be freed using `.clear()` method after finish operating with it to free the memory.
        pub fn filterIndexes(self: *@This(), map_fn: *const fn (element: *T, index: usize) bool, boundaries: IterationBoundaries) !?LinkedList(usize) {
            const range_start_index = boundaries.start_at_index orelse 0;
            const range_stop_index = boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var result_list = LinkedList(usize).init(self.allocator);
            errdefer result_list.clear();

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index) {
                    if (map_fn(item, counter)) {
                        try result_list.addToTail(counter);
                    }
                }
                counter += 1;
            }

            if (result_list.isEmpty()) {
                return null;
            }

            return result_list;
        }

        /// Gathers list elements that successfully pass filter function.
        ///
        /// If no one element passed filter functions returns `null`.
        ///
        /// Result list have to be freed using `.clear()` method after finish operating with it to free the memory.
        pub fn filterElements(self: *@This(), map_fn: *const fn (element: *T, index: usize) bool, boundaries: IterationBoundaries) !?LinkedList(*T) {
            const range_start_index = boundaries.start_at_index orelse 0;
            const range_stop_index = boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var result_list = LinkedList(*T).init(self.allocator);
            errdefer result_list.clear();

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index) {
                    if (map_fn(item, counter)) {
                        try result_list.addToTail(item);
                    }
                }
                counter += 1;
            }

            if (result_list.isEmpty()) {
                return null;
            }

            return result_list;
        }

        /// Gathers list nodes that successfully pass filter function.
        ///
        /// If no one element passed filter functions returns `null`.
        ///
        /// Result list have to be freed using `.clear()` method after finish operating with it to free the memory.
        pub fn filterNodes(self: *@This(), map_fn: *const fn (node: *Node, index: usize) bool, boundaries: IterationBoundaries) !?LinkedList(*Node) {
            const range_start_index = boundaries.start_at_index orelse 0;
            const range_stop_index = boundaries.stop_at_index orelse self.size();
            if (range_start_index > range_stop_index) {
                return LinkedListError.InvalidIterationBoundaries;
            }

            var counter: usize = 0;

            var result_list = LinkedList(*Node).init(self.allocator);
            errdefer result_list.clear();

            var nodes_iterator = self.nodesIterator(.head);
            while (nodes_iterator.next()) |item| {
                if (!(counter < range_stop_index)) break;
                if (counter >= range_start_index and counter < range_stop_index) {
                    if (map_fn(item, counter)) {
                        try result_list.addToTail(item);
                    }
                }
                counter += 1;
            }

            if (result_list.isEmpty()) {
                return null;
            }

            return result_list;
        }

        /// Creates slice from list.
        ///
        /// Slice have to be freed using `allocator.free(slice)` after finish operating with it to free the memory.
        pub fn toOwnedSlice(self: @This()) ![]T {
            var counter: usize = 0;
            var result_slice = try self.allocator.alloc(T, self.size());

            var elements_iterator = self.elementsIterator(.head);
            while (elements_iterator.next()) |item| {
                result_slice[counter] = item.*;
                counter += 1;
            }

            return result_slice;
        }
    };
}
