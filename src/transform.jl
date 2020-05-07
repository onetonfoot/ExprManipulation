# import Base: ==

# # https://stackoverflow.com/questions/55606017/postorder-traversal-of-an-n-ary-tree
# # https://www.geeksforgeeks.org/iterative-postorder-traversal-of-n-ary-tree/?ref=leftbar-rightbar
# function postorder(root::MExpr)
#     stack = Any[root]
#     last_child =  nothing

#     while !isempty(stack)
#         root = stack[end]
#         # node has no child, or one child has been visted, the process and pop it
#         if !haschildren(root) || (!isnothing(last_child) &&  last_child in children(root))
#             println(root)
#             pop!(stack)
#             last_child = root
#         else
#             append!(stack, reverse(root.args))
#         end
#     end
# end