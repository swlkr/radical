<<~ERB
  <%== form model: #{snake_case} do |f| %>
    #{inputs(leading: 4)}
    <%== f.submit 'Save' %>
  <% end %>
ERB
