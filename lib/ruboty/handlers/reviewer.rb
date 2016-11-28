require "terminal-table"

module Ruboty
  module Handlers
    class Reviewer < Base
      NAMESPACE = "reviewers".freeze

      on(
        /review list\z/m,
        description: "List reviewers and their current assignments",
        name: "list",
      )

      on(
        /review add (?<name>.+)\z/m,
        description: "Add new reviewer",
        name: "add",
      )

      on(
        /review bye (?<name>.+)\z/m,
        description: "Remove reviewer",
        name: "bye",
      )

      on(
        /review request (?<url>.+)\z/m,
        description: "Assign new issue to reviewer",
        name: "request",
      )

      on(
        /review finish (?<url>.+)\z/m,
        description: "Notify that review finished",
        name: "finish",
      )

      def list(message)
        table = Terminal::Table.new do |t|
          t << ["Reviewer", "Assignments"]
          t << :separator
          data.each do |name, urls|
            t << [
              name,
              urls.join("\n"),
            ]
          end
        end
        message.reply(code_block(table))
      end

      def add(message)
        name = message[:name].strip
        if data.key?(name)
          message.reply("#{name} has already been added to reviewers.")
        else
          data[name] = []
          message.reply("Welcome #{name}!")
        end
      end

      def bye(message)
        name = message[:name].strip
        if data.key?(name)
          data.delete(name)
          message.reply("Bye #{name}!")
        else
          message.reply("#{name} is not in reviewers.")
        end
      end

      def request(message)
        url = message[:url].strip
        name = lot_reviewer
        if name
          assign(name, url)
          message.reply("#{url} is assigned to #{name}")
        else
          message.reply("#{url} is not assigned.")
        end
      end

      def finish(message)
        url = message[:url].strip
        name = unassign(url)
        if name
          message.reply("Thank you, #{name}!")
        else
          message.reply("#{url} is not assigned")
        end
      end

      private

      def data
        robot.brain.data[NAMESPACE] ||= {}
      end

      def code_block(text)
        "```\n#{text}\n```"
      end

      def lot_reviewer
        scores = Hash.new { |h, k| h[k] = [] }
        data.each { |name, urls| scores[urls.count] << name }

        max_score = scores.keys.max
        scores[max_score].sample
      end

      def assign(name, url)
        data[name] << url
      end

      def unassign(url)
        data.each do |name, urls|
          if urls.include?(url)
            urls.delete(url)
            return name
          end
        end
        nil
      end
    end
  end
end
